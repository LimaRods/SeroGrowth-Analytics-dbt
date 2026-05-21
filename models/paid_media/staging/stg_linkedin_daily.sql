with source as (
    select * from {{ source('paid_media', 'fct_linkedin_daily') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_linkedin') }}
),

fx as (
    select * from {{ source('paid_media', 'usd_fx_rates') }}
),

joined as (
    select
        f.id,
        f.campaign_id,
        c.client_id,
        'linkedin_ads'                                                  as channel_id,
        c.campaign_name,
        f.day_date,
        date_trunc('week', f.day_date)::date                           as week_date,
        c.utm_campaign,
        f.utm_content,
        f.spend_native,
        f.currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)          as spend_usd,
        f.impressions,
        f.clicks,
        f.clicks_to_landing_page,
        f.engagements,
        f.conversions,
        f.click_conversions,
        f.view_through_conversions,
        f.leads,
        f.reach,
        f.avg_frequency,
        f.video_views,
        f.video_completions,
        f.total_engagements,
        f.total_conversion_value,
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
        and fx.week_starting  = date_trunc('week', f.day_date)
),

final as (
    select * from joined
)

select * from final
