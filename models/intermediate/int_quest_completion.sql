SELECT
    qc.id,
    qc.user_id,
    qc.type,
    qc.source,
    COALESCE(qc.symbol,qc.pool_symbol) AS product_symbol,
    qc.completed_at,
    --qc.symbol,
    qc.token_amount,
    --qc.pool_symbol,
    qc.symbol_x,
    qc.amount_x,
    qc.symbol_y,
    qc.amount_y,
    qc.duration,
    qc.awarded_points,
    --q.reward_type,
    --q.reward_token,
    --q.reward_amount,
    -- Base points logic
        CASE
        -- Hold quests (balance in USX/eUSX)
        WHEN qc.type = 'HOLD'
             AND qc.symbol IN ('USX', 'eUSX') 
        THEN qc.token_amount

        -- Exponent positions (special LP token)
        WHEN qc.source = 'EXPONENT'
             AND qc.symbol = 'Expo LP eUSX'
        THEN qc.token_amount

        -- Liquidity position: both sides incentivized if USX/eUSX pool
        WHEN qc.type = 'LIQUIDITY_POSITION'
             AND qc.pool_symbol IN ('USX/eUSX', 'eUSX/USX')
        THEN COALESCE(qc.amount_x,0) + COALESCE(qc.amount_y,0)

        -- Liquidity position: only one incentivized side
        WHEN qc.type = 'LIQUIDITY_POSITION'
             AND qc.symbol_x IN ('USX','eUSX') 
        THEN qc.amount_x

        WHEN qc.type = 'LIQUIDITY_POSITION'
             AND qc.symbol_y IN ('USX','eUSX') 
        THEN qc.amount_y

        -- Swaps use awarded points directly
        WHEN qc.type = 'SWAP' 
        THEN qc.awarded_points

        ELSE qc.awarded_points
    END AS base_points,
    q.multiplier_reward,
    q.category AS quest_category

FROM {{ ref("stg_quest_completions")}} qc
LEFT JOIN {{ ref("stg_quests")}} q
    ON qc.quest_id = q.id