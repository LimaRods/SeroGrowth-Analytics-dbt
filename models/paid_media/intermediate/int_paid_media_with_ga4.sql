{{
    config(
        materialized='incremental',
        unique_key='record_key',
        incremental_strategy='merge'
    )
}}

with paid as (
    select * from {{ ref('int_paid_media_weekly') }}
    {% if is_incremental() %}
        where week_date > (select max(week_date) from {{ this }})
    {% endif %}
),

ga4 as (
    select * from {{ ref('stg_ga4_weekly') }}
),

joined as (
    select
        p.record_key,
        p.channel_id,
        p.client_id,
        p.campaign_id,
        p.campaign_name,
        p.ad_group_id,
        p.ad_group_name,
        p.utm_campaign,
        p.utm_content,
        p.week_date,
        p.spend_native,
        p.currency_code,
        p.spend_usd,
        p.impressions,
        p.reach,
        p.link_clicks,
        p.engagement_clicks,
        p.engagements,
        p.result,
        p.result_type,
        p.conversions,
        p.data_quality_flag,
        g.ga4_sessions,
        g.ga4_users,
        g.engaged_sessions,
        g.avg_session_time,
        g.key_events,
        g.engagement_rate,
        case
            when p.utm_campaign = g.utm_campaign
             and p.utm_content  = g.utm_content      then 'ad_group'
            when p.utm_campaign = g.utm_campaign
             and g.utm_content  is null               then 'campaign'
            when p.channel_id   = g.linked_channel_id then 'channel'
            else 'unjoined'
        end                                             as attribution_join_tier
    from paid p
    left join ga4 g
        on  g.utm_campaign = p.utm_campaign
        and g.week_date    = p.week_date
        and g.client_id    = p.client_id
),

final as (
    select * from joined
)

select * from final
