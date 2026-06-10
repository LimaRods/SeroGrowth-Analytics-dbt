-- Thin pass-through over the append-only snapshot source. No dedup here — that
-- is the job of dim_deal_current (latest per deal).
select *
from {{ source('core', 'deal_snapshots') }}
