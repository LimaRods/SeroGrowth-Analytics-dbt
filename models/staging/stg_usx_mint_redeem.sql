SELECT
    id,
    timestamp_ntz,
    signature,
    requestor,
    collateral_mint,
    collateral_amount,
    redeemable_mint,
    redeemable_amount,
    type,
    ingested_at
FROM
    {{ source('internal', 'usx_mint_redeem') }}
