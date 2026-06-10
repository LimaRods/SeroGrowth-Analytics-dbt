-- Thin pass-through over the REGISTRY client master.
-- NOT YET POPULATED — empty until REGISTRY is seeded (see loader follow-up).
select *
from {{ source('registry', 'clients') }}
