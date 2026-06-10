with source as (
    select * from {{ source('paid_media', 'fct_linkedin_daily') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_linkedin') }}
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
        'linkedin_ads'                                                  as channel_id,
        c.campaign_name,
        c.utm_campaign,
        c.campaign_objective,
        f.ad_set_id,
        f.ad_set_name,
        f.ad_set_objective                                              as objective,
        f.ad_set_type,
        f.ad_set_cost_type,
        f.ad_set_daily_budget,
        f.utm_content,
        f.day_date,
        date_trunc('week', f.day_date)::date                            as week_date,
        f.spend_native,
        coalesce(c.currency_code, cl.linkedin_currency)                 as currency_code,
        round(f.spend_native * coalesce(fx.usd_rate, 1.0), 2)           as spend_usd,
        f.impressions,
        f.clicks,
        f.clicks_to_landing_page,
        f.reactions,
        f.comments,
        f.shares,
        f.follows,
        f.total_social_actions,
        f.total_engagements,
        f.engagement_rate,
        f.conversions,
        f.post_click_conversions,
        f.view_through_conversions,
        f.conversion_rate,
        f.cost_per_conversion,
        f.total_conversion_value,
        f.return_on_ad_spend,
        f.leads,
        f.video_views,
        f.video_completions,
        f.reach,
        f.avg_frequency,
        -- derived rates (CTR/CPM/CPC computed in dbt, not stored on fct)
        case when f.impressions > 0 then round(f.clicks / f.impressions::float, 6) end           as ctr,
        case when f.impressions > 0 then round(f.spend_native * 1000.0 / f.impressions, 4) end   as cpm_native,
        case when f.clicks      > 0 then round(f.spend_native / f.clicks, 4) end                 as cpc_native,
        case
            when fx.usd_rate is null and coalesce(c.currency_code, cl.linkedin_currency) != 'USD'
                then 'missing_fx_rate'
            else f.data_quality_flag
        end                                                             as data_quality_flag
    from source f
    left join campaigns c
        on c.campaign_id = f.campaign_id
    left join clients cl
        on cl.client_id = c.client_id
    left join fx
        on  fx.currency_code = coalesce(c.currency_code, cl.linkedin_currency)
        and fx.week_starting  = date_trunc('week', f.day_date)
),

final as (
    select * from joined
)

select * from final
