SELECT
    id,
    address AS user,
    token AS token_mint_address,
    {{ token_symbol('token') }} AS symbol,
    {{ token_amount_adj('amount_raw','token') }} AS amount,
    start_timestamp_ntz AS start_ts,
    end_timestamp_ntz AS end_ts

FROM
    {{ source('internal','token_balances')}}
WHERE  token IN ('6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG','3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC') --USX and eUSX