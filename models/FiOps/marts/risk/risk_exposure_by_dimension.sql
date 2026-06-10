-- RISK — aggregate current TRS exposure by venue / jurisdiction / currency.
-- Joins the latest MTM per deal to the deal's dimensions (from deal_terms),
-- so onshore vs offshore exposure is a first-class cut.
with mtm as (
    select * from {{ ref('risk_trs_mtm_latest') }}
),
dims as (
    select
        deal_id,
        currency,
        deal_terms:venue::string        as venue,
        deal_terms:jurisdiction::string as jurisdiction
    from {{ ref('dim_deal_current') }}
)
select
    coalesce(dims.venue, 'unknown')         as venue,
    coalesce(dims.jurisdiction, 'unknown')  as jurisdiction,
    coalesce(mtm.currency, dims.currency)   as currency,
    count(*)                                as trs_deals,
    sum(mtm.total_notional)                 as total_notional,
    sum(mtm.total_mtm_pnl)                  as total_mtm_pnl,
    sum(case when mtm.breached then 1 else 0 end) as breached_count
from mtm
left join dims on dims.deal_id = mtm.deal_id
group by 1, 2, 3
