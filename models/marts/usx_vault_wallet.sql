WITH vault_events AS (
    SELECT
        symbol,
        user,
        CASE WHEN type = 'CONFIRM_MINT' THEN amount ELSE 0 END AS amount_mints,
        CASE WHEN type = 'CONFIRM_REDEEM' THEN amount ELSE 0 END AS amount_redeems
        
    FROM {{ ref('stg_usx_mint_redeem') }}
    
),

metrics AS (
    SELECT
        user,
        symbol,
        SUM(amount_mints) AS total_tokens_locked,
        SUM(amount_redeems) AS total_tokens_unlocked
    FROM vault_events
    GROUP BY 1, 2
)

SELECT
    *
FROM
    metrics
ORDER BY total_tokens_locked DESC

