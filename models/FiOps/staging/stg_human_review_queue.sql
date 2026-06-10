-- Thin pass-through over the OPS human-review work queue.
-- NOT YET POPULATED — empty until the human-review/ops flow writes it.
select *
from {{ source('ops', 'human_review_queue') }}
