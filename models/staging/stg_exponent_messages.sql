
{{ config(materized = 'view') }}

SELECT
    signature,
    timestamp_ntz,
    address,
    type,
    mint_yt,
    mint_lp,
    {{ token_symbol('mint_yt') }} AS yt_symbol,
    {{ token_symbol('mint_lp') }} AS lp_symbol,
    {{ token_amount_adj('amount_raw','mint_lp') }} AS amount,
    market

FROM
    {{ source('internal', 'exponent_messages')}}