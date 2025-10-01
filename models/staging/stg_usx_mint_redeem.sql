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
WHERE
    timestamp_ntz >= TO_TIMESTAMP_NTZ('2025-09-30')
