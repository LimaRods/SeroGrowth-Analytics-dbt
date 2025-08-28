SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    {{ token_metadata('mint') }} AS symbol,
    amount,
    type

FROM
    {{ ref('stg_usx_mint_redeem') }}