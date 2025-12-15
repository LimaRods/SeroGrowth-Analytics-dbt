

-- IMPORTANT (run once per session if needed)
-- ALTER SESSION SET MAX_RECURSION_DEPTH = 10000;

WITH base AS (
    -- Normalize balance streaks
    SELECT
        user,
        pool_address,
        pool_symbol,
        pool_type,
        amount_x,
        amount_y,
        DATE(start_timestamp_ntz) AS start_date,
        COALESCE(DATE(end_timestamp_ntz), CURRENT_DATE()) AS end_date
    FROM {{ ref('stg_liquidity_clmm') }}
    WHERE amount_x > 0 OR amount_y > 0
),

-- Expand each balance streak into daily rows
recursive_daily AS (
    -- Anchor: first day of the streak
    SELECT
        user,
        pool_address,
        pool_symbol,
        pool_type,
        amount_x,
        amount_y,
        start_date,
        start_date AS date,
        end_date
    FROM base

    UNION ALL

    -- Recursive step: propagate forward day by day
    SELECT
        r.user,
        r.pool_address,
        r.pool_symbol,
        r.pool_type,
        r.amount_x,
        r.amount_y,
        r.start_date,
        DATEADD(day, 1, r.date) AS date,
        r.end_date
    FROM recursive_daily r
    WHERE r.date < r.end_date
),

-- Resolve overlapping streaks (keep the most recent per day)
deduped_daily AS (
    SELECT
        date,
        user,
        pool_type,
        pool_address,
        pool_symbol,
        amount_x,
        amount_y,
        ROW_NUMBER() OVER (
            PARTITION BY date, user, pool_address
            ORDER BY start_date DESC
        ) AS rn
    FROM recursive_daily
)

-- Final daily LP positions
SELECT
    date,
    user,
    pool_type,
    pool_address,
    pool_symbol,
    amount_x,
    amount_y
FROM deduped_daily
WHERE rn = 1
ORDER BY date, user, pool_symbol, pool_address