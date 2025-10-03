SELECT
    timestamp_ntz,
    signature,
    protocol,
    venue,
    user_shares AS user,
    symbol,
    amount,
    type

FROM (

    SELECT 
    *,
    'Yield Vault (eUSX)' AS venue,
    'Solstice' AS protocol,
    FROM
        {{ ref("stg_yield_vault")}}
)

ORDER BY timestamp_ntz DESC