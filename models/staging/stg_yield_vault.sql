

WITH base AS (
    SELECT
        id,
        timestamp_ntz,
        signature,
        user,
        user_shares,
        asset_mint AS token_mint_address,
        {{ token_symbol('asset_mint') }} AS symbol,
        {{ token_amount_adj('amount','asset_mint') }} AS amount,
        type
    FROM
        {{ source("internal", "yield_vault") }}
),

-- 🩵 Manual fix for missing USX lock (September 23, 2025)
manual_fix AS (
    SELECT
        'manual_usx_lock_fix_20250923' AS id,
        TO_TIMESTAMP_NTZ('2025-09-23 00:00:00') AS timestamp_ntz,
        NULL AS signature,
        NULL AS user,
        NULL AS user_shares,
        '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG' AS token_mint_address,  -- USX mint address
        'USX' AS symbol,
        55728634.4898 AS amount,
        'LOCK' AS type
)

--  Merge source + manual correction
SELECT
    *
FROM (
    SELECT * FROM base
    UNION ALL
    SELECT * FROM manual_fix
)
ORDER BY timestamp_ntz