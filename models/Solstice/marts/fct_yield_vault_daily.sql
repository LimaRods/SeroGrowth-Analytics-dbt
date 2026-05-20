WITH vault_events AS (
    SELECT
        DATE_TRUNC('day', timestamp_ntz) AS date,
        symbol,
        SUM(CASE WHEN type = 'LOCK' THEN amount ELSE 0 END) AS daily_mints,
        SUM(CASE WHEN type = 'UNLOCK' THEN amount ELSE 0 END) AS daily_redeems,
        SUM(CASE 
            WHEN type = 'LOCK' THEN amount 
            WHEN type = 'UNLOCK' THEN -amount 
            ELSE 0 END
        ) AS daily_netflow
    FROM {{ ref('stg_yield_vault') }}
    GROUP BY 1, 2
),

harvest_inflows AS (
    SELECT
        DATE_TRUNC('day', timestamp_ntz) AS date,
        symbol,
        SUM(amount) AS daily_mints,
        0 AS daily_redeems,
        SUM(amount) AS daily_netflow
    FROM {{ ref('stg_usx_yield_transfer') }}
    GROUP BY 1, 2
),

base AS (
    SELECT * FROM vault_events
    UNION ALL
    SELECT * FROM harvest_inflows
),

aggregated AS (
    SELECT
        date,
        symbol,
        SUM(daily_mints) AS daily_mints,
        SUM(daily_redeems) AS daily_redeems,
        SUM(daily_netflow) AS daily_netflow
    FROM base
    GROUP BY 1, 2
),

date_bounds AS (
    SELECT
        MIN(date) AS min_date,
        MAX(CURRENT_DATE()) AS max_date
    FROM aggregated
),

all_dates AS (
    SELECT DATEADD(day, n, db.min_date) AS date
    FROM date_bounds db
    JOIN LATERAL (
        SELECT SEQ4() AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 20000)) 
    ) seq
    WHERE DATEADD(day, n, db.min_date) <= db.max_date
),

all_symbols AS (
    SELECT DISTINCT symbol FROM aggregated
),

calendar_token AS (
    SELECT d.date, s.symbol
    FROM all_dates d
    CROSS JOIN all_symbols s
),

daily AS (
    SELECT
        c.date,
        c.symbol,
        COALESCE(a.daily_mints, 0) AS daily_deposits,
        COALESCE(a.daily_redeems, 0) AS daily_withdrawals,
        COALESCE(a.daily_netflow, 0) AS daily_netflow
    FROM calendar_token c
    LEFT JOIN aggregated a
        ON c.date = a.date AND c.symbol = a.symbol
),

seasons AS (
    SELECT *
    FROM {{ ref("dim_seasons") }}
),

final AS (
    SELECT
        d.date,
        d.symbol,
        d.daily_deposits,
        d.daily_withdrawals,
        SUM(d.daily_deposits) OVER (PARTITION BY d.symbol ORDER BY d.date) AS cumulative_deposits,
        SUM(d.daily_withdrawals) OVER (PARTITION BY d.symbol ORDER BY d.date) AS cumulative_withdrawals,
        SUM(d.daily_netflow) OVER (PARTITION BY d.symbol ORDER BY d.date) AS total_tokens_locked,
        s.season
    FROM daily d
    LEFT JOIN seasons s
        ON d.date >= s.start_date
        AND d.date <= s.end_date
)

SELECT *
FROM final
ORDER BY date, symbol