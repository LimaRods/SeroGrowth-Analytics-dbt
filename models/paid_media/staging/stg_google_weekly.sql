with source as (
    select * from {{ source('paid_media', 'fct_google_weekly') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_google') }}
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
        c.network_type,
        f.week_date,
        c.utm_campaign,
        f.spend_native,
        f.currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)          as spend_usd,
        f.impressions,
        f.link_clicks,
        f.engagement_clicks,
        f.click_type,
        f.conversions,
        f.cost_per_conversion,
        case
            when fx.usd_rate is null and f.currency_code != 'USD'
                then 'missing_fx_rate'
            else f.data_quality_flag
        end                                                             as data_quality_flag
    from source f
    left join campaigns c
        on c.campaign_id = f.campaign_id
    left join fx
        on  fx.currency_code = f.currency_code
        and fx.week_starting  = date_trunc('week', f.week_date)
),

final as (
    select * from joined
)

select * from final
