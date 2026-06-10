-- Thin pass-through over the REGISTRY source/connector master.
-- NOT YET POPULATED — empty until REGISTRY is seeded (see loader follow-up).
select *
from {{ source('registry', 'sources') }}
