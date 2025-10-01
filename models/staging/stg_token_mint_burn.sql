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
WHERE
    timestamp_ntz >= TO_TIMESTAMP_NTZ('2025-09-30')
