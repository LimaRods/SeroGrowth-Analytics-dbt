WITH base AS (
    -- Normalize liquidity position streaks
    SELECT
        user,
        symbol,
        market,
        amount,                                    -- already humanized
        DATE(start_timestamp_ntz) AS start_date,
        COALESCE(DATE(end_timestamp_ntz), CURRENT_DATE()) AS end_date
    FROM {{ ref('stg_liquidity_expo') }}
    WHERE amount > 0
),

-- 🔁 Expand each streak into daily rows
recursive_daily AS (
    -- Anchor: first day of the streak
    SELECT
        user,
        symbol,
        market,
        amount,
        start_date,
        start_date AS date,
        end_date
    FROM base

    UNION ALL

    -- Recursive step: move forward one day
    SELECT
        r.user,
        r.symbol,
        r.market,
        r.amount,
        r.start_date,
        DATEADD(day, 1, r.date) AS date,
        r.end_date
    FROM recursive_daily r
    WHERE r.date < r.end_date
),

-- 🧠 Resolve overlapping streaks (latest start_date wins)
deduped_daily AS (
    SELECT
        date,
        user,
        symbol,
        market,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY date, user, symbol, market
            ORDER BY start_date DESC
        ) AS rn
    FROM recursive_daily
)

-- 📊 Final daily Expo positions
SELECT
    date,
    user,
    symbol,
    market,
    amount AS position_amount
FROM deduped_daily
WHERE rn = 1
ORDER BY date, user, symbol, market