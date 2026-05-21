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
        f.ad_group_id,
        f.ad_group_name,
        c.utm_campaign,
        f.utm_content,
        f.week_date,
        f.spend_native,
        coalesce(f.currency_code, cl.x_currency)                        as currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)          as spend_usd,
        f.impressions,
        f.reach,
        f.frequency,
        f.link_clicks,
        f.engagements,
        f.result,
        c.result_type,
        f.conversions,
        case
            when fx.usd_rate is null and f.currency_code != 'USD'
                then 'missing_fx_rate'
            else f.data_quality_flag
        end                                                             as data_quality_flag
    from source f
    left join campaigns c
        on c.campaign_id = f.campaign_id
    left join clients cl
        on cl.client_id = c.client_id
    left join fx
        on  fx.currency_code = coalesce(f.currency_code, cl.x_currency)
        and fx.week_starting  = date_trunc('week', f.week_date)
),

final as (
    select * from joined
)

select * from final
