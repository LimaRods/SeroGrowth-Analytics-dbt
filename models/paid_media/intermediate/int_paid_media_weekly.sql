with x as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'x_ads\'', 'campaign_id', 'ad_group_id', 'week_date']) }} as record_key,
        'x_ads'             as channel_id,
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
        link_clicks,
        null::bigint        as engagement_clicks,
        engagements,
        result,
        result_type,
        conversions,
        objective,
        campaign_objective,
        data_quality_flag
    from {{ ref('stg_x_weekly') }}
),

linkedin_agg as (
    select
        campaign_id,
        client_id,
        channel_id,
        campaign_name,
        utm_campaign,
        utm_content,
        currency_code,
        week_date,
        sum(spend_native)           as spend_native,
        sum(spend_usd)              as spend_usd,
        sum(impressions)            as impressions,
        sum(reach)                  as reach,
        sum(clicks_to_landing_page) as link_clicks,
        sum(engagements)            as engagements,
        sum(conversions)            as conversions,
        max(objective)              as objective,
        max(campaign_objective)     as campaign_objective,
        max(data_quality_flag)      as data_quality_flag
    from {{ ref('stg_linkedin_daily') }}
    group by 1, 2, 3, 4, 5, 6, 7, 8
),

linkedin as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'linkedin_ads\'', 'campaign_id', 'week_date']) }} as record_key,
        channel_id,
        client_id,
        campaign_id,
        campaign_name,
        null                as ad_group_id,
        null                as ad_group_name,
        utm_campaign,
        utm_content,
        week_date,
        spend_native,
        currency_code,
        spend_usd,
        impressions,
        reach,
        link_clicks,
        null::bigint        as engagement_clicks,
        engagements,
        null::bigint        as result,
        'clicks'            as result_type,
        conversions,
        objective,
        campaign_objective,
        data_quality_flag
    from linkedin_agg
),

google as (
    select
        {{ dbt_utils.generate_surrogate_key(['\'google_ads\'', 'campaign_id', 'week_date']) }} as record_key,
        'google_ads'        as channel_id,
        client_id,
        campaign_id,
        campaign_name,
        null                as ad_group_id,
        null                as ad_group_name,
        utm_campaign,
        null                as utm_content,
        week_date,
        spend_native,
        currency_code,
        spend_usd,
        impressions,
        null::bigint        as reach,
        link_clicks,
        engagement_clicks,
        null::bigint        as engagements,
        null::bigint        as result,
        click_type          as result_type,
        conversions,
        objective,
        campaign_objective,
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
