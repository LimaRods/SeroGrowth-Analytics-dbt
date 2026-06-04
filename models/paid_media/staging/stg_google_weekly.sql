with source as (
    select * from {{ source('paid_media', 'fct_google_weekly') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_google') }}
),

clients as (
    select * from {{ source('paid_media', 'clients') }}
),

fx as (
    select * from {{ source('paid_media', 'usd_fx_rates') }}
),

joined as (
    select
        f.id,
        f.campaign_id,
        c.client_id,
        'google_ads'                                                    as channel_id,
        c.campaign_name,
        c.utm_campaign,
        c.campaign_objective,
        f.campaign_type                                                 as objective,
        f.campaign_type,
        f.week_date,
        f.spend_native,
        coalesce(c.currency_code, cl.google_currency)                   as currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)           as spend_usd,
        f.impressions,
        f.clicks,
        f.engagements,
        f.conversions,
        f.cost_per_conversion,
        f.impr_abs_top_pct,
        f.impr_top_pct,
        -- derived rates (CTR/CPM/CPC computed in dbt, not stored)
        case when f.impressions > 0 then round(f.clicks / f.impressions::float, 6) end           as ctr,
        case when f.impressions > 0 then round(f.spend_native * 1000.0 / f.impressions, 4) end   as cpm_native,
        case when f.clicks      > 0 then round(f.spend_native / f.clicks, 4) end                 as cpc_native,
        case
            when fx.usd_rate is null and coalesce(c.currency_code, cl.google_currency) != 'USD'
                then 'missing_fx_rate'
            else f.data_quality_flag
        end                                                             as data_quality_flag
    from source f
    left join campaigns c
        on c.campaign_id = f.campaign_id
    left join clients cl
        on cl.client_id = c.client_id
    left join fx
        on  fx.currency_code = coalesce(c.currency_code, cl.google_currency)
        and fx.week_starting  = date_trunc('week', f.week_date)
),

final as (
    select * from joined
)

select * from final
