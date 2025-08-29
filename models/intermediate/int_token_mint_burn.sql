SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    {{ token_metadata('mint') }} AS symbol,
    amount,
    type
FROM
    {{ ref("stg_token_mint_burn") }}