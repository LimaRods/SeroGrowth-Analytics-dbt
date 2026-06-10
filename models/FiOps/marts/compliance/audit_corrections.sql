-- COMPLIANCE — the correction audit trail. Every immutable field-level
-- correction across instruments: what changed (old → new), why, and who signed
-- it off. This is the CVM/ANBIMA "no silent UPDATE" evidence.
select
    client_id,
    deal_id,
    contract_id,
    instrument_type,
    event_type,
    payload:field::string         as corrected_field,
    payload:old_value::string     as old_value,
    payload:new_value::string     as new_value,
    payload:reason::string        as reason,
    metadata:reviewed_by::string  as reviewed_by,
    business_date,
    occurred_at
from {{ ref('deal_events_current') }}
where event_type like '%.corrected'
