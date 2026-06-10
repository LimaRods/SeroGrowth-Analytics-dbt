-- Current deal state = the latest snapshot per deal_id.
-- Replaces the former CORE.dim_deal_current DDL view; identical semantics, now
-- owned, tested and lineaged on the read side.
select *
from {{ ref('stg_deal_snapshots') }}
qualify row_number() over (partition by deal_id order by snapshot_at desc) = 1
