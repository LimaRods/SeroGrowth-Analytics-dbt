-- Deal events enriched with the resolved contract (→ client_id, template,
-- version) and the deal's current attributes. Replaces the former
-- CORE.deal_events_current DDL view. client_id is never stored on the
-- event/deal — it is resolved here via contract_id.
select
    ev.event_id,
    ev.event_index,
    ev.event_type,
    ev.deal_id,
    ev.contract_id,
    c.contract_template_id,
    c.contract_version,
    c.client_id,
    ev.execution_id,
    ev.business_date,
    ev.occurred_at,
    ev.payload,
    ev.metadata,
    d.instrument_type,
    d.asset_class,
    d.status        as deal_status
from {{ ref('stg_deal_events') }} ev
left join {{ ref('stg_contracts') }}    c on c.contract_id = ev.contract_id
left join {{ ref('dim_deal_current') }} d on d.deal_id     = ev.deal_id
