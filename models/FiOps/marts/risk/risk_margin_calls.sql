-- RISK — margin-call alert log. Every TRS mark-to-market breach, with the
-- adverse move, threshold and the call amount. One row per margin call.
select
    client_id,
    deal_id,
    contract_id,
    payload:ticker::string                as ticker,
    payload:as_of_date::date              as as_of_date,
    payload:current_price::float          as current_price,
    payload:total_notional::float         as total_notional,
    payload:total_mtm_pnl::float          as total_mtm_pnl,
    payload:mtm_move_pct::float           as mtm_move_pct,
    payload:margin_call_threshold::float  as margin_call_threshold,
    payload:call_amount::float            as call_amount,
    payload:currency::string              as currency,
    occurred_at
from {{ ref('deal_events_current') }}
where event_type = 'trs.margin_call'
