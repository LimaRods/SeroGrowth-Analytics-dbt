

WITH base AS (
    -- Normalize balance streaks
    SELECT
        user,
        symbol,
        token_mint_address,
        amount,                                    -- already adjusted
        DATE(start_ts) AS start_date,
        COALESCE(DATE(end_ts), CURRENT_DATE()) AS end_date
    FROM {{ ref('stg_token_balances') }}
    WHERE amount > 0
),

-- 🔁 Expand each streak into daily rows
recursive_daily AS (
    -- Anchor: first day of the streak
    SELECT
        user,
        symbol,
        token_mint_address,
        amount,
        start_date,
        start_date AS date,
        end_date
    FROM base

    UNION ALL

    -- Recursive step: next day
    SELECT
        r.user,
        r.symbol,
        r.token_mint_address,
        r.amount,
        r.start_date,
        DATEADD(day, 1, r.date) AS date,
        r.end_date
    FROM recursive_daily r
    WHERE r.date < r.end_date
),

-- 🧠 Resolve overlapping streaks (latest wins)
deduped_daily AS (
    SELECT
        date,
        user,
        symbol,
        token_mint_address,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY date, user, symbol
            ORDER BY start_date DESC
        ) AS rn
    FROM recursive_daily
)

-- 📊 Final daily token balances
SELECT
    date,
    user,
    symbol,
    token_mint_address,
    amount AS token_balance
FROM deduped_daily
WHERE rn = 1
ORDER BY date, user, symbol