WITH vault_events AS (
    SELECT
        symbol,
        user,
        CASE WHEN type = 'LOCK' THEN amount ELSE 0 END AS daily_mints,
        CASE WHEN type = 'UNLOCK' THEN amount ELSE 0 END AS daily_redeems
        
    FROM {{ ref('stg_yield_vault') }}
    
),

metrics AS (
    SELECT
        user,
        symbol,
        SUM(daily_mints) AS total_tokens_locked,
        SUM(daily_redeems) AS total_tokens_unlocked
    FROM vault_events
    GROUP BY 1, 2
)

SELECT
    *
FROM
    metrics
ORDER BY total_tokens_locked DESC

