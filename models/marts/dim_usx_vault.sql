WITH events AS (
    SELECT
        DATE_TRUNC('day', timestamp_ntz) AS date,
        user,
        symbol,
        CASE 
            WHEN type = 'CONFIRM_MINT'   THEN amount
            WHEN type = 'CONFIRM_REDEEM' THEN -amount
            ELSE 0
        END AS netflow
    FROM {{ ref('int_usx_mint_redeem') }}
),

-- 1) Netflow per day / user / token
daily_changes AS (
    SELECT
        date,
        user,
        symbol,
        SUM(netflow) AS daily_netflow
    FROM events
    GROUP BY 1, 2, 3
),

-- 2) First positive deposit date per (user, token)
first_deposit_pairs AS (
    SELECT
        user,
        symbol,
        MIN(date) AS first_deposit_date
    FROM daily_changes
    WHERE daily_netflow > 0
    GROUP BY 1, 2
),

-- 3) Global bounds for calendar
date_bounds AS (
    SELECT 
        MIN(date) AS min_date,
        MAX(date) AS max_date
    FROM daily_changes
),

-- 4) All dates (generated independently; constant ROWCOUNT)
all_dates AS (
    SELECT DATEADD(day, SEQ4(), db.min_date) AS date
    FROM date_bounds db,
         TABLE(GENERATOR(ROWCOUNT => 20000))  -- bump if needed
    WHERE DATEADD(day, SEQ4(), db.min_date) <= db.max_date
),

-- 5) FULL calendar = dates × (user, token) via CROSS JOIN,
--    then trimmed to start on each pair's first deposit
calendar_user_token AS (
    SELECT
        d.date,
        p.user,
        p.symbol
    FROM all_dates d
    CROSS JOIN first_deposit_pairs p
    WHERE d.date >= p.first_deposit_date
),

-- 6) Fill missing days with 0 netflow
calendar_with_changes AS (
    SELECT
        c.date,
        c.user,
        c.symbol,
        COALESCE(dc.daily_netflow, 0) AS daily_netflow
    FROM calendar_user_token c
    LEFT JOIN daily_changes dc
      ON dc.date   = c.date
     AND dc.user = c.user
     AND dc.symbol = c.symbol
),

-- 7) Cumulative balance per (user, token) over the full calendar
balance_timeseries AS (
    SELECT
        date,
        user,
        symbol,
        SUM(daily_netflow) OVER (PARTITION BY user, symbol ORDER BY date) AS tokens_locked
    FROM calendar_with_changes
)

-- 8) Output (optional: filter zeros)
SELECT
    date,
    user,
    symbol,
    tokens_locked
FROM balance_timeseries
WHERE tokens_locked != 0  
ORDER BY date, user, symbol