
{{ config(materized = 'view') }}

SELECT
    signature,
    timestamp_ntz,
    address,
    type,
    mint_yt,
    mint_lp,
    amount_raw/POW(10,6) AS amount,
    market

FROM
    {{ source('internal', 'exponent_messages')}}