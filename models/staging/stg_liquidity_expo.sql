SELECT
    id,
    address AS user,
    market,
    token AS token_mint_address,
    {{ token_symbol('token') }} AS symbol,
    {{ token_amount_adj('amount_raw','token') }} AS amount,
    start_timestamp_ntz,
    end_timestamp_ntz

FROM
    {{ source("internal","exponent_liquidity_positions") }}