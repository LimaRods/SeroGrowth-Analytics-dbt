SELECT
    -- Primary identifiers
    id,
    description,
    category,
    active,
    created_at,
    expiry,
    source,
    type,
    global_limit,
    user_limit,
    cooldown,

    -- Reward info
    reward_type,
    reward_token,
    reward_amount,
    duration,
    multiplier_reward,
    amount_type,

    -- Token enrichment
    token,
    {{ token_symbol('token') }}                              AS symbol,
    {{ token_amount_adj('amount_raw', 'token') }}            AS token_amount,

    -- Pool-specific enrichment
    pool,
    pool_type,
    {{ token_symbol("token_x") }} || '/' || {{ token_symbol("token_y") }} AS pool_symbol,

    token_x,
    {{ token_symbol('token_x') }}                            AS symbol_x,
    {{ token_amount_adj('amountx_raw', 'token_x') }}         AS amount_x,

    token_y,
    {{ token_symbol('token_y') }}                            AS symbol_y,
    {{ token_amount_adj('amounty_raw', 'token_y') }}         AS amount_y,

    lpamount_raw,
    tick_lower_index,
    tick_upper_index,
    tick_type,

    -- Metadata
    ingested_at

FROM {{ source("internal","quests") }}