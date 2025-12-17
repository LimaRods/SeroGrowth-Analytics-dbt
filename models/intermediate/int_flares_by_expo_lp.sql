WITH registered_users AS (
    SELECT address
    FROM {{ ref('user_addresses') }}
),

blacklisted_users AS (
    SELECT address
    FROM {{ ref('blacklisted_addresses') }}
),

/* 1) Base streaks (already humanized in STG) */
base AS (
    SELECT
        user,
        market,
        token_mint_address,
        symbol,
        amount,

        DATE(start_timestamp_ntz) AS start_date,

        -- cap open streaks at yesterday (no points for today)
        LEAST(
            DATE(COALESCE(end_timestamp_ntz, CURRENT_DATE())),
            DATEADD(day, -1, CURRENT_DATE())
        ) AS end_date
    FROM {{ ref('stg_liquidity_expo') }}
    WHERE amount > 0
),

/* 2) Exclude registered + blacklisted users */
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

/* 3) Convert "threshold streaks" → EFFECTIVE windows
      A streak is only valid until the day before a newer one starts */
windowed AS (
    SELECT
        e.*,
        LEAD(e.start_date) OVER (
            PARTITION BY
                e.user,
                e.market,
                e.token_mint_address
            ORDER BY e.start_date
        ) AS next_start_date
    FROM eligible e
),

/* 4) Final effective date per streak */
effective AS (
    SELECT
        user,
        market,
        token_mint_address,
        symbol,
        amount,
        start_date,

        LEAST(
            end_date,
            COALESCE(DATEADD(day, -1, next_start_date), end_date)
        ) AS effective_end_date
    FROM windowed
),

/* 5) Compute days held (inclusive) */
final AS (
    SELECT
        *,
        DATEDIFF(day, start_date, effective_end_date) + 1 AS days_held
    FROM effective
    WHERE effective_end_date >= start_date
)

SELECT
    user,
    market,
    token_mint_address,
    symbol,
    amount,
    start_date,
    effective_end_date AS end_date,
    days_held,

    /* Flares = TVL × days × multiplier */
    amount
      * days_held
      * {{ tvl_multiplier('token_mint_address', 'symbol') }}
      AS flares

FROM final
ORDER BY start_date, user, market