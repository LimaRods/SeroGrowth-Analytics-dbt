with paid as (
    select * from {{ ref('int_paid_media_weekly') }}
),

ga4 as (
    -- Aggregate GA4 to (client, week, utm_content) so the ad-group join is 1:1.
    -- utm_content is normalized (lower/trim) to match the paid side resiliently.
    select
        client_id,
        week_date,
        lower(trim(utm_content))                      as utm_content_key,
        sum(ga4_sessions)                             as ga4_sessions,
        sum(ga4_users)                                as ga4_users,
        sum(engaged_sessions)                         as engaged_sessions,
        sum(new_users)                                as new_users,
        sum(returning_users)                          as returning_users,
        sum(event_count)                              as event_count,
        sum(key_events)                               as key_events,
        sum(total_revenue)                            as total_revenue,
        case when sum(ga4_sessions) > 0
             then round(sum(engaged_sessions) / sum(ga4_sessions)::float, 6) end as engagement_rate,
        avg(avg_session_time)                         as avg_session_time,
        avg(events_per_session)                       as events_per_session,
        avg(session_key_event_rate)                   as session_key_event_rate,
        avg(user_key_event_rate)                      as user_key_event_rate,
        avg(engaged_sessions_per_active_user)         as engaged_sessions_per_active_user
    from {{ ref('stg_ga4_weekly') }}
    where utm_content is not null
    group by 1, 2, 3
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
        g.new_users,
        g.returning_users,
        g.event_count,
        g.total_revenue,
        g.events_per_session,
        g.session_key_event_rate,
        g.user_key_event_rate,
        g.engaged_sessions_per_active_user,
        case
            when g.utm_content_key is not null then 'ad_group'
            else 'unjoined'
        end                                             as attribution_join_tier
    from paid p
    left join ga4 g
        on  g.utm_content_key = lower(trim(p.utm_content))
        and g.week_date       = p.week_date
        and g.client_id       = p.client_id
),

final as (
    select * from joined
)

select * from final
