SELECT
    id,
    timestamp_ntz,
    signature,
    requestor AS user,
    collateral_mint AS mint,
    collateral_amount AS amount,
    type
FROM
    {{ source('internal', 'usx_mint_redeem') }}
