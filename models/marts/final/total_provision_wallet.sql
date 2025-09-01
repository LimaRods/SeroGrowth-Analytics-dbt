SELECT
    user,
    protocol,
    venue,
    symbol,
    total_tokens_locked,
    total_tokens_unlocked 

FROM (
    SELECT 
    *,
    'USX Vault' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("usx_vault_wallet")}}
    UNION ALL

    SELECT 
    *,
    'Yield Vault (eUSX)' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("yield_vault_wallet")}}
)

ORDER BY total_tokens_locked DESC, user, venue