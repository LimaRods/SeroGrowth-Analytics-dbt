{{ config(materialized='view') }}

WITH quest_completions AS (
    SELECT *
    FROM {{ ref("stg_quest_completions") }}
),

quests AS (
    SELECT *
    FROM {{ ref("stg_quests") }}
),

-- 1️⃣ Filter only multiplier quests
multiplier_quests AS (
    SELECT *
    FROM quests
    WHERE reward_type = 'multiplier'
),

-- 2️⃣ Split logic by source type
-- A. Direct match for EUSX / USX / KAMINO
direct_match AS (
    SELECT
        qc.*,
        q.category,
        q.reward_type,
        q.reward_token,
        q.reward_amount,
        q.multiplier_reward,
        q.amount_type,
        q.source AS quest_source
    FROM quest_completions qc
    LEFT JOIN multiplier_quests q
        ON qc.quest_id = q.id
    WHERE qc.source IN ('EUSX','USX','KAMINO')
),

-- B. Pool match for ORCA / RAYDIUM
pool_match AS (
    SELECT
        qc.*,
        q.category,
        q.reward_type,
        q.reward_token,
        q.reward_amount,
        q.multiplier_reward,
        q.amount_type,
        q.source AS quest_source
    FROM quest_completions qc
    LEFT JOIN multiplier_quests q
        ON qc.source = q.source
        AND qc.type = q.type
        AND qc.pool = q.pool
    WHERE qc.source IN ('ORCA','RAYDIUM')
),

-- C. Non-multiplier quests (token rewards)
token_quests AS (
    SELECT
        qc.*,
        NULL AS category,
        'token' AS reward_type,
        NULL AS reward_token,
        NULL AS reward_amount,
        NULL AS multiplier_reward,
        NULL AS amount_type,
        NULL AS quest_source
    FROM quest_completions qc
    WHERE qc.source NOT IN ('EUSX','USX','KAMINO','ORCA','RAYDIUM')
),

-- Combine all sources, no duplicates
joined AS (
    SELECT * FROM direct_match
    UNION ALL
    SELECT * FROM pool_match
    UNION ALL
    SELECT * FROM token_quests
),

-- 3️⃣ Compute base_points & multiplier fields (no effective calc yet)
calc_points AS (
    SELECT
        j.*,

        CASE
            -- 🪙 token-based quests → base = awarded
            WHEN j.reward_type = 'token'
            THEN j.awarded_points

            -- 💠 multiplier quests for EUSX/USX/KAMINO → base = token_amount
            WHEN j.reward_type = 'multiplier'
                 AND j.source IN ('EUSX','USX','KAMINO')
            THEN j.token_amount

            -- 🌊 multiplier quests for ORCA/RAYDIUM → base = amount_x + amount_y
            WHEN j.reward_type = 'multiplier'
                 AND j.source IN ('ORCA','RAYDIUM')
            THEN COALESCE(j.amount_x,0) + COALESCE(j.amount_y,0)

            ELSE j.awarded_points
        END AS base_points,

        -- 🎚️ multipliers
        CASE
            WHEN j.source IN ('EUSX','USX','KAMINO') THEN j.multiplier_reward
        END AS multiplier,

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
    multiplier,
    multiplier_x,
    multiplier_y,
    reward_type,
    reward_token,
    reward_amount
FROM calc_points