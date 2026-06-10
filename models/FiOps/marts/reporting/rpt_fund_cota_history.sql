-- CLIENT REPORTING — fund NAV cota history (emissão do preço da cota).
-- One row per published cota: the per-quota price investors subscribe/redeem at.
select
    client_id,
    deal_id,
    contract_id,
    payload:valuation_date::date  as valuation_date,
    payload:cota_type::string     as cota_type,
    payload:cota_value::float     as cota_value,
    payload:currency::string      as currency,
    occurred_at                   as published_at
from {{ ref('deal_events_current') }}
where event_type = 'nav.cota_published'
