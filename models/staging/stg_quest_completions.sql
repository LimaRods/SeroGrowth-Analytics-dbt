SELECT
    id,
    type,
    quest_id,
    source,
    user_id,
    completed_at_ntz AS completed_at,
    token,
    {{token_symbol('token')}} AS symbol,
    amount AS raw_amount,
    {{ token_amount_adj('amount', 'token')}} AS amount,
    awarded_points,
    duration
    
    
FROM
    {{ source("internal","quest_completions")}}