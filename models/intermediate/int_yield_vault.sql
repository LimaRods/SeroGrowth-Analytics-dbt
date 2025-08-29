SELECT
    id,
    signature,
    timestamp_ntz,
    user,
    asset_mint,
    {{ token_metadata('asset_mint') }} AS symbol,
    amount,
    type

FROM
    {{ ref('stg_yield_vault') }}