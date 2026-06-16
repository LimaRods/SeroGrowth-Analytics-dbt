/* Unified weekly paid-media union across channels.
   Click model is intentionally simple: only `clicks` and `engagements` — no
   link_clicks / engagement_clicks split.
     X        → clicks = link_clicks,  engagements = Engagements
     LinkedIn → clicks = clicks,       engagements = total_engagements
     Google   → clicks = clicks,       engagements = engagements
   Grain: native per channel (X ad-group, LinkedIn ad-set, Google campaign) × week. */

with x as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'x_ads\'', 'campaign_id', 'ad_group_id', 'week_date']) }} as record_key,
        'x_ads'              as channel_id,
        client_id,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,
        utm_campaign,
        utm_content,
        week_date,
        spend_native,
        currency_code,
        spend_usd,
        impressions,
        reach,
        clicks,
        engagements,
        null::bigint         as conversions,
        objective,
        campaign_objective,
        video_views,
        video_played_25,
        video_played_50,
        video_played_75,
        video_completions,
        video_views_2s,
        sessions,
        app_installs,
        app_sign_ups,
        app_sessions,
        app_checkouts_initiated,
        skan_app_installs,
        null::numeric(8,6)   as impr_abs_top_pct,
        null::numeric(8,6)   as impr_top_pct,
        data_quality_flag
    from {{ ref('stg_x_weekly') }}
),

linkedin_agg as (
    select
        campaign_id,
        client_id,
        channel_id,
        campaign_name,
        ad_set_id,
        ad_set_name,
        utm_campaign,
        campaign_objective,
        utm_content,
        currency_code,
        week_date,
        sum(spend_native)        as spend_native,
        sum(spend_usd)           as spend_usd,
        sum(impressions)         as impressions,
        sum(reach)               as reach,
        sum(clicks)              as clicks,
        sum(total_engagements)   as engagements,
        sum(conversions)         as conversions,
        max(objective)           as objective,
        max(data_quality_flag)   as data_quality_flag
    from {{ ref('stg_linkedin_daily') }}
    group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),

linkedin as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'linkedin_ads\'', 'campaign_id', 'ad_set_id', 'week_date']) }} as record_key,
        channel_id,
        client_id,
        campaign_id,
        campaign_name,
        ad_set_id            as ad_group_id,    /* LinkedIn ad-set maps to the shared ad_group_id slot */
        ad_set_name          as ad_group_name,
        utm_campaign,
        utm_content,
        week_date,
        spend_native,
        currency_code,
        spend_usd,
        impressions,
        reach,
        clicks,
        engagements,
        conversions,
        objective,
        campaign_objective,
        null::bigint         as video_views,
        null::bigint         as video_played_25,
        null::bigint         as video_played_50,
        null::bigint         as video_played_75,
        null::bigint         as video_completions,
        null::bigint         as video_views_2s,
        null::bigint         as sessions,
        null::bigint         as app_installs,
        null::bigint         as app_sign_ups,
        null::bigint         as app_sessions,
        null::bigint         as app_checkouts_initiated,
        null::bigint         as skan_app_installs,
        null::numeric(8,6)   as impr_abs_top_pct,
        null::numeric(8,6)   as impr_top_pct,
        data_quality_flag
    from linkedin_agg
),

google as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'google_ads\'', 'campaign_id', 'week_date']) }} as record_key,
        'google_ads'         as channel_id,
        client_id,
        campaign_id,
        campaign_name,
        null                 as ad_group_id,
        null                 as ad_group_name,
        utm_campaign,
        null                 as utm_content,
        week_date,
        spend_native,
        currency_code,
        spend_usd,
        impressions,
        null::bigint         as reach,
        clicks,
        engagements,
        conversions,
        objective,
        campaign_objective,
        null::bigint         as video_views,
        null::bigint         as video_played_25,
        null::bigint         as video_played_50,
        null::bigint         as video_played_75,
        null::bigint         as video_completions,
        null::bigint         as video_views_2s,
        null::bigint         as sessions,
        null::bigint         as app_installs,
        null::bigint         as app_sign_ups,
        null::bigint         as app_sessions,
        null::bigint         as app_checkouts_initiated,
        null::bigint         as skan_app_installs,
        impr_abs_top_pct,
        impr_top_pct,
        data_quality_flag
    from {{ ref('stg_google_weekly') }}
),

unioned as (
    select * from x
    union all
    select * from linkedin
    union all
    select * from google
),

final as (
    select * from unioned
)

select * from final
