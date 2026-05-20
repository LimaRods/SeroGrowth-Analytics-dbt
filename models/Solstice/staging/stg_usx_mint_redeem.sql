

WITH base AS (
    SELECT
        id,
        timestamp_ntz,
        signature,
        requestor AS user,
        collateral_mint AS token_mint_address,
        {{ token_symbol('collateral_mint') }} AS symbol,
        {{ token_amount_adj('collateral_amount','collateral_mint') }} AS amount, 
        type
    FROM
        {{ source('internal', 'usx_mint_redeem') }}
),

--  Manual fix for missing USDC collateral deposit (Sept 23, 2025)
manual_fix AS (
    SELECT
        'manual_usdc_fix_20250923' AS id,
        TO_TIMESTAMP_NTZ('2025-09-23 00:00:00') AS timestamp_ntz,
        NULL AS signature,
        NULL AS user,
        'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v' AS token_mint_address,  -- USDC mint address
        'USDC' AS symbol,
        61522946.2823 AS amount,
        'CONFIRM_MINT' AS type
)

--  Merge raw source data + manual correction
SELECT
*
FROM (
SELECT * FROM base
UNION ALL
SELECT * FROM manual_fix
)
ORDER BY timestamp_ntz