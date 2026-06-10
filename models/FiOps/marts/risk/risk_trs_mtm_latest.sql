-- RISK — current synthetic exposure: the LATEST mark-to-market per TRS deal.
-- One row per TRS deal that has been marked.
select
    client_id,
    deal_id,
    contract_id,
    payload:ticker::string         as ticker,
    payload:as_of_date::date       as as_of_date,
    payload:total_notional::float  as total_notional,
    payload:total_mtm_pnl::float   as total_mtm_pnl,
    payload:mtm_move_pct::float    as mtm_move_pct,
    payload:breached::boolean      as breached,
    payload:currency::string       as currency,
    occurred_at
from {{ ref('deal_events_current') }}
where event_type = 'trs.marked_to_market'
qualify row_number() over (partition by deal_id order by occurred_at desc, event_index desc) = 1
