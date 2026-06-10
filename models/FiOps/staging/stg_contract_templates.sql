-- Thin pass-through over the contract templates ("bytecode") registry.
select *
from {{ source('contract', 'contract_templates') }}
