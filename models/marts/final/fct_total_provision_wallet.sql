SELECT
    date,
    user,
    protocol,
    venue,
    symbol,
    tokens_locked 

FROM (
    SELECT 
    *,
    'USX Vault' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("fct_usx_vault_wallet")}}
    UNION ALL

    SELECT 
    *,
    'Yield Vault (eUSX)' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("fct_yield_vault_wallet")}}
)

ORDER BY date, user, venue