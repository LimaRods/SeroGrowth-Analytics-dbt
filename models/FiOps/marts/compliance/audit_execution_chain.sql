-- COMPLIANCE — tamper-evidence. Each execution should chain to the previous one
-- on its contract via previous_execution_hash. chain_ok = FALSE flags a break
-- (a missing/forged link). One row per execution, in chain order per contract.
with ordered as (
    select
        contract_id,
        execution_id,
        execution_type,
        deal_id,
        status,
        requested_at,
        previous_execution_hash,
        execution_hash,
        row_number() over (partition by contract_id order by requested_at) as seq,
        lag(execution_hash) over (partition by contract_id order by requested_at) as expected_prev
    from {{ ref('stg_executions') }}
)
select
    contract_id,
    seq,
    execution_id,
    execution_type,
    deal_id,
    status,
    requested_at,
    previous_execution_hash,
    execution_hash,
    case
        when seq = 1 then previous_execution_hash is null
        else previous_execution_hash = expected_prev
    end as chain_ok
from ordered
