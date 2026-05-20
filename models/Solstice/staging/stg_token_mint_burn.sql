

WITH base AS (
    SELECT
        id,
        timestamp_ntz,
        signature,
        from_address AS user,
        mint AS token_mint_address,
        {{ token_symbol('mint') }} AS symbol,
        {{ token_amount_adj('amount','mint') }} AS amount,
        type
    FROM
        {{ source('internal', 'token_mint_burn') }}
),

-- Manual corrections for missing migration data
manual_fixes AS (
    SELECT
        'manual_usx_fix_20250923' AS id,
        TO_TIMESTAMP_NTZ('2025-09-23 00:00:00') AS timestamp_ntz,
        NULL AS signature,
        NULL AS user,
        'USX_MINT_MANUAL' AS token_mint_address,
        'USX' AS symbol,
        61522946.2823 AS amount,
        'MINT' AS type

    UNION ALL

    SELECT
        'manual_eusx_fix_20250923' AS id,
        TO_TIMESTAMP_NTZ('2025-09-23 00:00:00') AS timestamp_ntz,
        NULL AS signature,
        NULL AS user,
        'EUSX_MINT_MANUAL' AS token_mint_address,
        'eUSX' AS symbol,
        55728634.4898 AS amount,
        'MINT' AS type
),

--  Union all base data with the manual adjustments
combined AS (
    SELECT * FROM base
    UNION ALL
    SELECT * FROM manual_fixes
),

seasons AS (
    SELECT * FROM {{ ref('dim_seasons') }}
)

SELECT
    c.id,
    c.timestamp_ntz,
    c.signature,
    c.user,
    c.token_mint_address,
    c.symbol,
    c.amount,
    c.type,
    s.season
FROM combined c
LEFT JOIN seasons s
    ON DATE_TRUNC('day', c.timestamp_ntz) >= s.start_date
    AND DATE_TRUNC('day', c.timestamp_ntz) <= s.end_date