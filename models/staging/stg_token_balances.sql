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
WHERE
    token IN ('7QC4zjrKA6XygpXPQCKSS9BmAsEFDJR6awiHSdgLcDvS', 'Gkt9h4QWpPBDtbaF5HvYKCc87H5WCRTUtMf77HdTGHBt') -- USX/eUSX Replace that with a macro