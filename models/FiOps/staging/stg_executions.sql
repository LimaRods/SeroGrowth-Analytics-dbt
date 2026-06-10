-- Thin pass-through over the append-only execution log (the hash chain).
select *
from {{ source('core', 'executions') }}
