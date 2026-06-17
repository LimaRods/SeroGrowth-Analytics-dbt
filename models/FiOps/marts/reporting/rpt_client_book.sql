-- CLIENT REPORTING — the client's current book.
-- One row per (client, deal) at its latest state, with the onshore/offshore
-- venue, jurisdiction and currency dimensions surfaced from deal_terms.
select
    c.client_id,
    d.contract_id,
    c.contract_template_id,
    d.deal_id,
    d.instrument_type,
    d.asset_class,
    d.operation_type,
    d.currency,
    d.deal_terms:venue::string        as venue,
    d.deal_terms:jurisdiction::string as jurisdiction,
    d.deal_terms:ticker::string       as ticker,
    d.deal_terms:fund_id::string      as fund_id,
    d.status,
    d.completion_status,
    d.business_date,
    d.confidence_score
from {{ ref('dim_deal_current') }} d
left join {{ ref('stg_contracts') }} c on c.contract_id = d.contract_id
where d.asset_class <> 'system'
