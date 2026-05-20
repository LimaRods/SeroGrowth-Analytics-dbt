{{
    config(
        materialized = 'view'
    )

}}

WITH registered_users AS (
    SELECT address
    FROM {{ ref('user_addresses') }}
),

blacklisted_users AS (
    SELECT address
    FROM {{ ref('blacklisted_addresses') }}
),

/* 1️⃣ Normalize raw CLMM balance streaks (timestamp-safe) */
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

        start_timestamp_ntz AS start_ts,

        /* cap open streaks at yesterday 23:59:59 */
        LEAST(
            COALESCE(end_timestamp_ntz, DATEADD(second, -1, CURRENT_TIMESTAMP())),
            DATEADD(second, -1, DATEADD(day, 1, CURRENT_DATE()))
        ) AS end_ts
    FROM {{ ref('stg_liquidity_clmm') }}
    WHERE (amount_x > 0 OR amount_y > 0)
      AND pool_address IN (
            '2e3WeM4WwdEqwTtRnWN3gJSbhNg1P6Aj2y7kEdfrYbix', 
            'AUr5EVRwGDsKB2EeS1V63ncjHXDNRDLVfBP47qNvPoVf',
            'EWivkwNtcxuPsU6RyD7Pfvs7u9Yv8nQ79tJ7xgGyPrp6',
            'BkvKpstxgeEJYzvFnWWuAbTDcrFMJBty3kXxUfGG9D7n'
        )
),

/* 2️⃣ Exclude registered & blacklisted users */
eligible AS (
    SELECT b.*
    FROM base b
    LEFT JOIN registered_users r
        ON b.user = r.address
    LEFT JOIN blacklisted_users bl
        ON b.user = bl.address
    WHERE r.address IS NULL
      AND bl.address IS NULL
      AND b.start_ts < b.end_ts
),

/* 3️⃣ Resolve overlapping LP streaks
      (newer streak overrides older ones) */
windowed AS (
    SELECT
        e.*,
        LEAD(e.start_ts) OVER (
            PARTITION BY
                e.user,
                e.pool_address
            ORDER BY e.start_ts
        ) AS next_start_ts
    FROM eligible e
),

/* 4️⃣ Compute effective non-overlapping windows */
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
        start_ts,

        LEAST(
            end_ts,
            COALESCE(DATEADD(second, -1, next_start_ts), end_ts)
        ) AS effective_end_ts
    FROM windowed
),

/* 5️⃣ FULL DAYS ONLY (Solstice rule) */
final AS (
    SELECT
        user,
        pool_address,
        pool_symbol,
        pool_type,
        symbol_x,
        amount_x,
        symbol_y,
        amount_y,
        start_ts,
        effective_end_ts,

        FLOOR(
            DATEDIFF(second, start_ts, effective_end_ts) / 86400
        ) AS days_held
    FROM effective
    WHERE effective_end_ts > start_ts
)

-- 🎯 Final output (ready for incentive calculation)
SELECT
    user,
    pool_address,
    pool_type,
    pool_symbol,
    symbol_x,
    amount_x,
    symbol_y,
    amount_y,
    start_ts,
    effective_end_ts AS end_ts,
    days_held,

    (
        {{ tvl_multiplier("pool_address","symbol_x") }} * amount_x +
        {{ tvl_multiplier("pool_address","symbol_y") }} * amount_y
    ) * days_held AS flares

FROM final
WHERE days_held >= 1
ORDER BY start_ts, user, pool_address