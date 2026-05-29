with source as (
    select * from {{ source('paid_media', 'fct_x_weekly') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_x') }}
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
        'x_ads'                                                         as channel_id,
        c.campaign_name,
        c.utm_campaign,
        c.x_objective                                                   as campaign_objective,
        f.objective,
        f.ad_group_id,
        f.ad_group_name,
        f.utm_content,
        f.week_date,
        f.spend_native,
        coalesce(c.currency_code, cl.x_currency)                        as currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)            as spend_usd,
        f.ad_group_total_budget,
        f.impressions,
        f.reach,
        f.frequency,
        f.link_clicks AS clicks,
        f.status                                                        as ad_group_status,
        case
            when fx.usd_rate is null and coalesce(c.currency_code, cl.x_currency) != 'USD'
                then 'missing_fx_rate'
            else f.data_quality_flag
        end                                                             as data_quality_flag
    from source f
    left join campaigns c
        on c.campaign_id = f.campaign_id
    left join clients cl
        on cl.client_id = c.client_id
    left join fx
        on  fx.currency_code = coalesce(c.currency_code, cl.x_currency)
        and fx.week_starting  = date_trunc('week', f.week_date)
),

final as (
    select * from joined
)

select * from final
