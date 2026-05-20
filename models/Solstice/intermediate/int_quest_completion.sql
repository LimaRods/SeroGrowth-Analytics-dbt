{{ config(materialized='view') }}

WITH quest_completions AS (
    SELECT *
    FROM {{ ref("stg_quest_completions") }}
),

quests AS (
    SELECT *
    FROM {{ ref("stg_quests") }}
),

-- Season lookup
seasons AS (
    SELECT *
    FROM {{ ref("dim_seasons") }}
),

-- Split multiplier and token quests
multiplier_quests AS (
    SELECT *
    FROM quests
    WHERE reward_type = 'multiplier'
),
token_quests AS (
    SELECT *
    FROM quests
    WHERE reward_type <> 'multiplier'
),

-- A. Direct match for EUSX / USX / KAMINO
direct_match AS (
    SELECT
        qc.*,
        q.category,
        q.reward_type,
        q.reward_token,
        q.reward_amount,
        q.multiplier_reward AS multiplier,
        NULL AS multiplier_x,
        NULL AS multiplier_y,
    FROM quest_completions qc
    INNER JOIN multiplier_quests q
        ON qc.quest_id = q.id
    WHERE qc.source IN ('EUSX','USX','KAMINO', 'EXPONENT')
),

-- B. Dual join for ORCA / RAYDIUM (amount_type X & Y)
pool_match AS (
    SELECT
        qc.*,
        COALESCE(qx.category, qy.category) AS category,
        COALESCE(qx.reward_type, qy.reward_type) AS reward_type,
        COALESCE(qx.reward_token, qy.reward_token) AS reward_token,
        COALESCE(qx.reward_amount, qy.reward_amount) AS reward_amount,
        NULL AS multiplier,
        qx.multiplier_reward AS multiplier_x,
        qy.multiplier_reward AS multiplier_y
    FROM quest_completions qc
    INNER JOIN multiplier_quests qx
        ON qc.source = qx.source
        AND qc.type = qx.type
        AND qc.pool = qx.pool
        AND qx.amount_type = 'X'
    INNER JOIN multiplier_quests qy
        ON qc.source = qy.source
        AND qc.type = qy.type
        AND qc.pool = qy.pool
        AND qy.amount_type = 'Y'
    WHERE qc.source IN ('ORCA','RAYDIUM')
),

-- C. Token-based quests (non-multiplier)
token_based AS (
    SELECT
        qc.*,
        q.category,
        q.reward_type,
        q.reward_token,
        q.reward_amount,
        NULL AS multiplier,
        NULL AS multiplier_x,
        NULL AS multiplier_y
    FROM quest_completions qc
    INNER JOIN token_quests q
        ON qc.quest_id = q.id
),

-- Combine all sources
joined AS (
    SELECT * FROM direct_match
    UNION ALL
    SELECT * FROM pool_match
    UNION ALL
    SELECT * FROM token_based
),

-- Compute base_points
calc_points AS (
    SELECT
        j.*,
        CASE
            WHEN j.reward_type = 'token' THEN j.awarded_points
            WHEN j.source IN ('EUSX','USX','KAMINO') THEN j.token_amount
            WHEN j.source IN ('ORCA','RAYDIUM') THEN COALESCE(j.amount_x,0) + COALESCE(j.amount_y,0)
            ELSE j.awarded_points
        END AS base_points
    FROM joined j
),

combined_points AS (
    SELECT
        id,
        user_id,
        type,
        source,
        quest_id,
        pool,
        pool_type,
        completed_at,
        category AS quest_category,
        symbol,
        pool_symbol,
        symbol_x,
        amount_x,
        symbol_y,
        amount_y,
        token_amount,
        duration,
        awarded_points,
        base_points,
        multiplier,
        multiplier_x,
        multiplier_y,
        reward_type,
        reward_token,
        reward_amount
    FROM calc_points

    UNION ALL

    SELECT
        id,
        user_id,
        type,
        source,
        NULL             AS quest_id,
        NULL             AS pool,
        NULL             AS pool_type,
        created_at       AS completed_at,
        'ON_CHAIN'       AS quest_category,
        symbol,
        NULL             AS pool_symbol,
        NULL             AS symbol_x,
        NULL             AS amount_x,
        NULL             AS symbol_y,
        NULL             AS amount_y,
        NULL             AS token_amount,
        NULL             AS duration,
        awarded_points,
        NULL             AS base_points,
        NULL             AS multiplier,
        NULL             AS multiplier_x,
        NULL             AS multiplier_y,
        NULL             AS reward_type,
        NULL             AS reward_token,
        NULL             AS reward_amount
    FROM {{ ref('stg_exponent_point') }}
)

SELECT
    cp.id,
    cp.user_id,
    cp.type,
    cp.source,
    cp.quest_id,
    cp.pool,
    cp.pool_type,
    cp.completed_at,
    cp.quest_category,
    CASE
        WHEN cp.source IN ('RAYDIUM', 'ORCA') THEN cp.pool_symbol
        WHEN cp.source = 'EXPONENT' THEN cp.symbol
        WHEN cp.source IN ('KAMINO', 'USX', 'EUSX') THEN cp.type || ' ' || cp.symbol
        ELSE cp.source
    END AS product,
    cp.symbol,
    cp.pool_symbol,
    cp.symbol_x,
    cp.amount_x,
    cp.symbol_y,
    cp.amount_y,
    cp.token_amount,
    cp.duration,
    cp.awarded_points,
    cp.base_points,
    cp.multiplier,
    cp.multiplier_x,
    cp.multiplier_y,
    cp.reward_type,
    cp.reward_token,
    cp.reward_amount,

    -- Season enrichment
    s.season

FROM combined_points cp
LEFT JOIN seasons s
    ON cp.completed_at >= s.start_date
    AND cp.completed_at <= s.end_date