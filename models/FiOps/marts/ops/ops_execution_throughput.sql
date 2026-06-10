-- OPS — operational throughput. Execution volume by source connector, instrument
-- and status: where work comes from and whether it succeeds. One row per
-- (source, instrument, action, status).
select
    e.source_id,
    c.contract_template_id  as instrument,
    e.execution_type,
    e.status,
    count(*)                as execution_count,
    min(e.requested_at)     as first_at,
    max(e.requested_at)     as last_at
from {{ ref('stg_executions') }} e
left join {{ ref('stg_contracts') }} c on c.contract_id = e.contract_id
group by 1, 2, 3, 4
