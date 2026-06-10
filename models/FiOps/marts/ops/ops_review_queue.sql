-- OPS — live human-review backlog (open items, age, assignee, decision).
-- STRUCTURAL PROTOTYPE: empty until the human-review/ops flow writes
-- OPS.human_review_queue. Shape is ready so the dashboard can be built now.
select
    review_id,
    deal_id,
    contract_id,
    source_id,
    fields,
    status,
    assigned_to,
    reviewer_id,
    notes,
    created_at,
    decided_at
from {{ ref('stg_human_review_queue') }}
