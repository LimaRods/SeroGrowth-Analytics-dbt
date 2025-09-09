SELECT
    id,
    address AS user,
    pool AS pool_address,
    {{token_symbol("token_x")}} || '/' || {{token_symbol("token_y")}} AS pool_symbol,
    type AS pool_type,
    {{token_symbol("token_x")}} AS symbol_x,
    {{ token_amount_adj('amount_x_raw','token_x') }} AS amount_x,
    {{token_symbol("token_y")}} AS symbol_y,
    {{ token_amount_adj('amount_y_raw','token_x') }} AS amount_y,
    lp_token,
    lp_position,
    start_timestamp_ntz,
    end_timestamp_ntz

FROM
    {{ source("internal","liquidity_clmm") }}