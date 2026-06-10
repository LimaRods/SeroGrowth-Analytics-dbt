-- Thin pass-through over the append-only event source.
select *
from {{ source('core', 'deal_events') }}
