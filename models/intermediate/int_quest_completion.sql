SELECT
    qc.id,
    ua.address,
    qc.type,
    qc.quest_id,
    qc.source,
    qc.completed_at,
    qc.symbol,
    qc.amount,
    qc.duration,
    qc.awarded_points,
    q.reward_type,
    q.reward_token,
    q.reward_amount,
    q.multiplier_reward,
    q.category AS quest_category

FROM
    {{ ref("stg_quest_completions")}} qc
LEFT JOIN {{ ref("user_addresses")}} ua
    ON qc.user_id = ua.user_id
LEFT JOIN {{ ref("stg_quests")}} q
    ON qc.quest_id = q.id
