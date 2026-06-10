-- Thin pass-through over the append-only event source.
select *
from {{ source('operation_db', 'deal_events') }}
