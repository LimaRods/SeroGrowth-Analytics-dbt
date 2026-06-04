/* Grain: finest sub-campaign unit per channel, weekly.
     X        → ad group × week
     LinkedIn → ad set × week   (ads rolled up; ad_group_id = ad_set_id)
     Google   → campaign × week (no sub-campaign level in the export)
   For a true campaign rollup use mart_campaign_weekly. */
with base as (
    select * from {{ ref('int_paid_media_with_ga4') }}
),

clients as (
    select * from {{ source('paid_media', 'clients') }}
),

final as (
    select
        b.record_key,
        b.week_date,
        b.channel_id,
        b.client_id,
        cl.client_name,
        b.campaign_id,
        b.campaign_name,
        b.ad_group_id,
        b.ad_group_name,
        b.utm_campaign,
        b.utm_content,
        b.objective,
        b.campaign_objective,

        /* Spend */
        b.spend_native,
        b.currency_code,
        b.spend_usd,

        /* Volume */
        b.impressions,
        b.reach,
        b.clicks,
        b.engagements,
        b.conversions,
        b.video_views,
        b.video_played_25,
        b.video_played_50,
        b.video_played_75,
        b.video_completions,
        b.video_views_2s,
        b.sessions,
        b.app_installs,
        b.app_sign_ups,
        b.app_sessions,
        b.app_checkouts_initiated,
        b.skan_app_installs,
        b.impr_abs_top_pct,
        b.impr_top_pct,

        /* Derived metrics */
        case
            when b.impressions > 0
                then round(b.clicks / b.impressions::float, 6)
        end                                                             as ctr,

        case
            when b.impressions > 0
                then round(b.spend_usd * 1000.0 / b.impressions, 4)
        end                                                             as cpm_usd,

        case
            when b.clicks > 0
                then round(b.spend_usd / b.clicks, 4)
        end                                                             as cpc_usd,

        case
            when b.conversions > 0
                then round(b.spend_usd / b.conversions::float, 4)
        end                                                             as cpa_usd,

        /* Derived cost-per (X engagement metrics; NULL where the count is NULL/0) */
        case when b.video_views             > 0 then round(b.spend_usd / b.video_views, 4) end             as cost_per_video_view_usd,
        case when b.video_completions       > 0 then round(b.spend_usd / b.video_completions, 4) end       as cost_per_video_completion_usd,
        case when b.sessions                > 0 then round(b.spend_usd / b.sessions, 4) end                as cost_per_session_usd,
        case when b.app_installs            > 0 then round(b.spend_usd / b.app_installs, 4) end            as cost_per_app_install_usd,
        case when b.app_sign_ups            > 0 then round(b.spend_usd / b.app_sign_ups, 4) end            as cost_per_app_signup_usd,
        case when b.app_sessions            > 0 then round(b.spend_usd / b.app_sessions, 4) end            as cost_per_app_session_usd,
        case when b.app_checkouts_initiated > 0 then round(b.spend_usd / b.app_checkouts_initiated, 4) end as cost_per_app_checkout_usd,
        case when b.skan_app_installs       > 0 then round(b.spend_usd / b.skan_app_installs, 4) end       as cost_per_skan_install_usd,

        /* GA4 attribution */
        b.ga4_sessions,
        b.ga4_users,
        b.engaged_sessions,
        b.avg_session_time,
        b.key_events,
        b.engagement_rate,
        b.attribution_join_tier,

        b.data_quality_flag
    from base b
    left join clients cl
        on cl.client_id = b.client_id
)

select * from final
