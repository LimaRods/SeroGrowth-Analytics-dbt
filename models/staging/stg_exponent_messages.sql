{{ config(materialized='table') }}

WITH events AS (
    SELECT
        signature,
        timestamp_ntz,
        address,
        type,
        mint_yt,
        mint_lp,
        {{ token_symbol('mint_yt') }} AS yt_symbol,
        {{ token_symbol('mint_lp') }} AS lp_symbol,
        {{ token_amount_adj('amount_raw','mint_lp') }} AS amount,
        market
    FROM {{ source('internal', 'exponent_messages') }}
),

seasons AS (
    SELECT * FROM {{ ref('dim_seasons') }}
)

SELECT
    e.signature,
    e.timestamp_ntz,
    e.address,
    e.type,
    e.mint_yt,
    e.mint_lp,
    e.yt_symbol,
    e.lp_symbol,
    e.amount,
    e.market,
    s.season
FROM events e
LEFT JOIN seasons s
    ON DATE_TRUNC('day', e.timestamp_ntz) >= s.start_date
    AND DATE_TRUNC('day', e.timestamp_ntz) <= s.end_date