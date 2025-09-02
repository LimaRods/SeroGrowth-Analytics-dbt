SELECT
    timestamp_ntz,
    signature,
    protocol,
    venue,
    user,
    symbol,
    amount,
    type

FROM (
    SELECT 
    *,
    'USX Vault' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("stg_usx_mint_redeem")}}
    UNION ALL

    SELECT 
    *,
    'Yield Vault (eUSX)' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("stg_yield_vault")}}
)

ORDER BY timestamp_ntz DESC