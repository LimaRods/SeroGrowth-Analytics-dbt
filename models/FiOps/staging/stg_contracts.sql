-- Thin pass-through over the deployed-contracts source. contract_id resolves
-- template + version + client_id — the join that keeps those off events/deals.
select *
from {{ source('contract', 'contracts') }}
