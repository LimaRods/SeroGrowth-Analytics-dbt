-- CLIENT / OPS REPORTING — the equity settlement blotter.
-- One row per settled equity trade: cash settled, fees and derived cost basis.
select
    client_id,
    deal_id,
    contract_id,
    payload:ticker::string            as ticker,
    payload:side::string              as side,
    payload:filled_quantity::number   as filled_quantity,
    payload:average_price::float      as average_price,
    payload:gross_amount::float       as gross_amount,
    payload:total_fees::float         as total_fees,
    payload:net_amount::float         as net_amount,
    payload:currency::string          as currency,
    payload:settlement_date::date     as settlement_date
from {{ ref('deal_events_current') }}
where event_type = 'equity.settled'
