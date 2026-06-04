with paid as (
    select * from {{ ref('int_paid_media_weekly') }}
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
        p.clicks,
        p.engagements,
        p.conversions,
        p.video_views,
        p.video_played_25,
        p.video_played_50,
        p.video_played_75,
        p.video_completions,
        p.video_views_2s,
        p.sessions,
        p.app_installs,
        p.app_sign_ups,
        p.app_sessions,
        p.app_checkouts_initiated,
        p.skan_app_installs,
        p.impr_abs_top_pct,
        p.impr_top_pct,
        p.objective,
        p.campaign_objective,
        p.data_quality_flag,
        g.ga4_sessions,
        g.ga4_users,
        g.engaged_sessions,
        g.avg_session_time,
        g.key_events,
        g.engagement_rate,
        case
            when g.utm_content is not null then 'ad_group'
            else 'unjoined'
        end                                             as attribution_join_tier
    from paid p
    left join ga4 g
        on  g.utm_content = p.utm_content
        and g.week_date   = p.week_date
        and g.client_id   = p.client_id
),

final as (
    select * from joined
)

select * from final
