SELECT
    id,
    timestamp_ntz,
    signature,
    from_address AS user,
    mint,
    amount,
    type
FROM
    {{ source('internal', 'token_mint_burn') }}
