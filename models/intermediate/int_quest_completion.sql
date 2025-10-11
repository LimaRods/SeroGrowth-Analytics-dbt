{{ config(materialized='view') }}


WITH quest_completions AS (
    SELECT *
    FROM {{ ref("stg_quest_completions") }}
),

quests AS (
    SELECT *
    FROM {{ ref("stg_quests") }}
),

-- only multiplier quests
multiplier_quests AS (
    SELECT *
    FROM quests
    WHERE reward_type = 'multiplier'
),

-- 2️ join completions with quests using source rules
joined AS (
    SELECT
        qc.id,
        qc.user_id,
        qc.type,
        qc.source,
        qc.quest_id,
        qc.completed_at,
        qc.token,
        qc.symbol,
        qc.token_amount,
        qc.pool_symbol,
        qc.symbol_x,
        qc.amount_x,
        qc.symbol_y,
        qc.amount_y,
        qc.awarded_points,
        qc.pool,
        qc.pool_type,

        q.category,
        q.reward_type,
        q.reward_token,
        q.reward_amount,
        q.multiplier_reward,
        q.amount_type,

        -- trace which logic was used to join
        CASE
            WHEN qc.source IN ('EUSX', 'USX', 'KAMINO') THEN 'quest_id'
            WHEN qc.source IN ('ORCA', 'RAYDIUM') THEN 'pool_match'
            ELSE 'none'
        END AS multiplier_source_flag,

        -- assign multiplier correctly per context
        CASE
            WHEN qc.source IN ('ORCA', 'RAYDIUM') THEN
                CASE
                    WHEN q.amount_type = 'X' THEN q.multiplier_reward
                    WHEN q.amount_type = 'Y' THEN q.multiplier_reward
                    ELSE NULL
                END
            WHEN qc.source IN ('EUSX', 'USX', 'KAMINO') THEN q.multiplier_reward
            ELSE NULL
        END AS merged_multiplier

    FROM quest_completions qc
    LEFT JOIN multiplier_quests q
        ON (
            (
                qc.source IN ('EUSX','USX','KAMINO')
                AND qc.quest_id = q.id
            )
            OR (
                qc.source IN ('ORCA','RAYDIUM')
                AND qc.source = q.source
                AND qc.type = q.type
                AND qc.pool = q.pool
            )
        )
),

-- 3️⃣ compute base points only (no multiplier math yet)
calc_points AS (
    SELECT
        j.*,

        CASE
            -- token-based quests → base = awarded
            WHEN j.reward_type = 'token'
            THEN j.awarded_points

            -- multiplier quests for EUSX/USX/KAMINO → base = token_amount
            WHEN j.reward_type = 'multiplier'
                 AND j.source IN ('EUSX','USX','KAMINO')
            THEN j.token_amount

            -- multiplier quests for ORCA/RAYDIUM → base = amount_x + amount_y
            WHEN j.reward_type = 'multiplier'
                 AND j.source IN ('ORCA','RAYDIUM')
            THEN COALESCE(j.amount_x,0) + COALESCE(j.amount_y,0)

            ELSE j.awarded_points
        END AS base_points,

        -- separate multiplier columns for ORCA/RAYDIUM
        CASE
            WHEN j.source IN ('ORCA','RAYDIUM') AND j.amount_type = 'X' THEN j.multiplier_reward
        END AS multiplier_x,

        CASE
            WHEN j.source IN ('ORCA','RAYDIUM') AND j.amount_type = 'Y' THEN j.multiplier_reward
        END AS multiplier_y

    FROM joined j
)

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
    awarded_points,
    base_points,
    multiplier_x,
    multiplier_y,
    merged_multiplier AS multiplier_applied,
    multiplier_source_flag,
    reward_type,
    reward_token,
    reward_amount
FROM calc_points