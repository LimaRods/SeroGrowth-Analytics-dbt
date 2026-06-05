/* Grain: campaign × week. True campaign rollup across all channels.
   Paid metrics are summed from int_paid_media_weekly (pre-GA4 join, so the
   GA4 fan-out can't double-count). GA4 is aggregated to campaign grain and
   joined once. For sub-campaign (ad group / ad set) detail use mart_ad_group_weekly. */

with paid as (
    select * from {{ ref('int_paid_media_weekly') }}
),

paid_agg as (
    select
        channel_id,
        client_id,
        campaign_id,
        campaign_name,
        utm_campaign,
        campaign_objective,
        currency_code,
        week_date,
        sum(spend_native)      as spend_native,
        sum(spend_usd)         as spend_usd,
        sum(impressions)       as impressions,
        sum(reach)             as reach,
        sum(clicks)            as clicks,
        sum(engagements)       as engagements,
        sum(conversions)       as conversions,
        sum(video_views)             as video_views,
        sum(video_played_25)         as video_played_25,
        sum(video_played_50)         as video_played_50,
        sum(video_played_75)         as video_played_75,
        sum(video_completions)       as video_completions,
        sum(video_views_2s)          as video_views_2s,
        sum(sessions)                as sessions,
        sum(app_installs)            as app_installs,
        sum(app_sign_ups)            as app_sign_ups,
        sum(app_sessions)            as app_sessions,
        sum(app_checkouts_initiated) as app_checkouts_initiated,
        sum(skan_app_installs)       as skan_app_installs,
        max(impr_abs_top_pct)        as impr_abs_top_pct,   /* non-additive %; Google is 1 row/campaign-week so max = identity */
        max(impr_top_pct)            as impr_top_pct,
        max(data_quality_flag) as data_quality_flag
    from paid
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

ga4 as (
    /* Aggregate GA4 to (client, utm_campaign, week) once, so joining to the
       campaign-grain paid rows is 1:1 and can't fan out. Assumes ingestion
       keeps a campaign as EITHER content-level rows OR a single campaign-level
       (utm_content NULL) fallback row — never both — per the schema doc. */
    select
        client_id,
        lower(trim(utm_campaign))   as utm_campaign_key,
        week_date,
        sum(ga4_sessions)     as ga4_sessions,
        sum(ga4_users)        as ga4_users,
        sum(engaged_sessions) as engaged_sessions,
        sum(new_users)        as new_users,
        sum(returning_users)  as returning_users,
        sum(event_count)      as event_count,
        sum(key_events)       as key_events,
        sum(total_revenue)    as total_revenue,
        case when sum(ga4_sessions) > 0
             then round(sum(engaged_sessions) / sum(ga4_sessions)::float, 6)
        end                   as engagement_rate,
        avg(avg_session_time)                 as avg_session_time,
        avg(events_per_session)               as events_per_session,
        avg(session_key_event_rate)           as session_key_event_rate,
        avg(user_key_event_rate)              as user_key_event_rate,
        avg(engaged_sessions_per_active_user) as engaged_sessions_per_active_user
    from {{ ref('stg_ga4_weekly') }}
    where utm_campaign is not null
    group by 1, 2, 3
),

clients as (
    select * from {{ source('paid_media', 'clients') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.channel_id', 'p.campaign_id', 'p.week_date']) }} as record_key,
        p.week_date,
        p.channel_id,
        p.client_id,
        cl.client_name,
        p.campaign_id,
        p.campaign_name,
        initcap(replace(p.campaign_name, '-', ' '))    as campaign_label,
        p.utm_campaign,
        p.campaign_objective,

        /* Spend */
        p.spend_native,
        p.currency_code,
        p.spend_usd,

        /* Volume */
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

        /* Derived metrics */
        case when p.impressions > 0 then round(p.clicks / p.impressions::float, 6) end      as ctr,
        case when p.impressions > 0 then round(p.spend_usd * 1000.0 / p.impressions, 4) end as cpm_usd,
        case when p.clicks       > 0 then round(p.spend_usd / p.clicks, 4) end              as cpc_usd,
        case when p.conversions  > 0 then round(p.spend_usd / p.conversions::float, 4) end   as cpa_usd,

        /* Derived cost-per (X engagement metrics; NULL where the count is NULL/0) */
        case when p.video_views             > 0 then round(p.spend_usd / p.video_views, 4) end             as cost_per_video_view_usd,
        case when p.video_completions       > 0 then round(p.spend_usd / p.video_completions, 4) end       as cost_per_video_completion_usd,
        case when p.sessions                > 0 then round(p.spend_usd / p.sessions, 4) end                as cost_per_session_usd,
        case when p.app_installs            > 0 then round(p.spend_usd / p.app_installs, 4) end            as cost_per_app_install_usd,
        case when p.app_sign_ups            > 0 then round(p.spend_usd / p.app_sign_ups, 4) end            as cost_per_app_signup_usd,
        case when p.app_sessions            > 0 then round(p.spend_usd / p.app_sessions, 4) end            as cost_per_app_session_usd,
        case when p.app_checkouts_initiated > 0 then round(p.spend_usd / p.app_checkouts_initiated, 4) end as cost_per_app_checkout_usd,
        case when p.skan_app_installs       > 0 then round(p.spend_usd / p.skan_app_installs, 4) end       as cost_per_skan_install_usd,

        /* GA4 attribution (campaign grain) */
        g.ga4_sessions,
        g.ga4_users,
        g.engaged_sessions,
        g.new_users,
        g.returning_users,
        g.event_count,
        g.key_events,
        g.total_revenue,
        g.engagement_rate,
        g.avg_session_time,
        g.events_per_session,
        g.session_key_event_rate,
        g.user_key_event_rate,
        g.engaged_sessions_per_active_user,

        p.data_quality_flag
    from paid_agg p
    left join ga4 g
        on  g.client_id        = p.client_id
        and g.utm_campaign_key = lower(trim(p.utm_campaign))
        and g.week_date        = p.week_date
    left join clients cl
        on cl.client_id = p.client_id
)

select * from final
