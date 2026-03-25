WITH market_metadata AS {{ exponent_market_metadata() }},

deduped_addresses AS (
    SELECT
        address,
        MIN(user_id) AS user_id
    FROM {{ ref('user_addresses') }}
    GROUP BY address
)

SELECT
    ep.id,
    ep.created_at,
    COALESCE(ud.user_id,ep.wallet) As user_id,
     ep.wallet,
    ep.source_type AS type,
    'EXPONENT' AS source,
    ep.amount AS awarded_points,
    ep.market,
    CASE
        WHEN ep.source_type = 'YIELD_TRADE'        THEN 'YT-'  || md.market_name
        WHEN ep.source_type = 'LIQUIDITY_POSITION' THEN 'ELP-' || md.market_name
    END AS symbol

FROM {{ source("internal", "exponent_points") }} ep
LEFT JOIN market_metadata md
    ON ep.market = md.market_id
LEFT JOIN deduped_addresses ud
    ON ep.wallet = ud.address