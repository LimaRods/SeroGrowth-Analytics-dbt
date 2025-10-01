SELECT
    id,
    type,
    quest_id,
    source,
    user_id,
    completed_at_ntz AS completed_at,

    -- Generic token enrichment (SWAP, HOLD, Exponent Yield/Liquidity Quests)
    token,
    {{ token_symbol('token') }}        AS symbol,
    {{ token_amount_adj('amount', 'token') }} AS token_amount,

    -- Pool-specific enrichment
    {{token_symbol("token_x")}} || '/' || {{token_symbol("token_y")}} AS pool_symbol,
    token_x,
    {{ token_symbol('token_x') }}      AS symbol_x,
    {{ token_amount_adj('amountx_raw', 'token_x') }} AS amount_x,

    token_y,
    {{ token_symbol('token_y') }}      AS symbol_y,
    {{ token_amount_adj('amounty_raw', 'token_y') }} AS amount_y,


    -- Quest completion metadata
    awarded_points,
    duration,
    pool,
    pool_type,
    tick_lower_index,
    tick_upper_index,
    market

FROM 
    {{ source("internal","quest_completions") }}
WHERE
    completed_at_ntz >= TO_TIMESTAMP_NTZ('2025-09-30')