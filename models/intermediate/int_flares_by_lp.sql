

WITH registered_users AS (
    SELECT address
    FROM {{ ref('user_addresses') }}
),

blacklisted_users AS (
    SELECT address
    FROM {{ ref('blacklisted_addresses') }}
),

base AS (
    SELECT
        user,
        pool_address,
        pool_symbol,
        pool_type,
        symbol_x,
        amount_x,
        symbol_y,
        amount_y,
        DATE(start_timestamp_ntz) AS start_date,

        -- open streaks capped at yesterday
        LEAST(
            DATE(COALESCE(end_timestamp_ntz, CURRENT_DATE())),
            DATEADD(day, -1, CURRENT_DATE())
        ) AS end_date
    FROM {{ ref('stg_liquidity_clmm') }}
    WHERE (amount_x > 0 OR amount_y > 0)
      AND pool_address IN (
            '2e3WeM4WwdEqwTtRnWN3gJSbhNg1P6Aj2y7kEdfrYbix', 
            'AUr5EVRwGDsKB2EeS1V63ncjHXDNRDLVfBP47qNvPoVf',
            'EWivkwNtcxuPsU6RyD7Pfvs7u9Yv8nQ79tJ7xgGyPrp6',
            'BkvKpstxgeEJYzvFnWWuAbTDcrFMJBty3kXxUfGG9D7n'
        )
),

eligible AS (
    SELECT b.*
    FROM base b
    LEFT JOIN registered_users r
        ON b.user = r.address
    LEFT JOIN blacklisted_users bl
        ON b.user = bl.address
    WHERE r.address IS NULL
      AND bl.address IS NULL
      AND b.start_date <= b.end_date
),

/* 
   KEY STEP:
   Convert overlapping LP balance streaks into effective windows.
   Older streak ends the day before the next newer streak starts.
*/
windowed AS (
    SELECT
        e.*,
        LEAD(e.start_date) OVER (
            PARTITION BY
                e.user,
                e.pool_address
            ORDER BY e.start_date
        ) AS next_start_date
    FROM eligible e
),

effective AS (
    SELECT
        user,
        pool_address,
        pool_symbol,
        pool_type,
        symbol_x,
        amount_x,
        symbol_y,
        amount_y,
        start_date,

        LEAST(
            end_date,
            COALESCE(DATEADD(day, -1, next_start_date), end_date)
        ) AS effective_end_date
    FROM windowed
),

final AS (
    SELECT
        *,
        /* inclusive duration */
        DATEDIFF(day, start_date, effective_end_date) + 1 AS days_held
    FROM effective
    WHERE effective_end_date >= start_date
)

-- Final output (ready for flares)
SELECT
    user,
    pool_address,
    pool_type,
    pool_symbol,
    symbol_x,
    amount_x,
    symbol_y,
    amount_y,
    start_date,
    effective_end_date AS end_date,
    days_held,

    (
        {{ tvl_multiplier("pool_address","symbol_x") }} * amount_x +
        {{ tvl_multiplier("pool_address","symbol_y") }} * amount_y
    ) * days_held AS flares

FROM final
ORDER BY start_date, user, pool_address