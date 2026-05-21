{{
    config(
        materialized='incremental',
        unique_key='record_key',
        incremental_strategy='merge'
    )
}}

with base as (
    select * from {{ ref('int_paid_media_with_ga4') }}
    {% if is_incremental() %}
        where week_date > (select max(week_date) from {{ this }})
    {% endif %}
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
        b.result_type,

        /* Spend */
        b.spend_native,
        b.currency_code,
        b.spend_usd,

        /* Volume */
        b.impressions,
        b.reach,
        b.link_clicks,
        b.engagement_clicks,
        b.engagements,
        b.result,
        b.conversions,

        /* Derived metrics */
        case
            when b.impressions > 0
                then round(b.link_clicks / b.impressions::float, 6)
        end                                                             as ctr,

        case
            when b.impressions > 0
                then round(b.spend_usd * 1000.0 / b.impressions, 4)
        end                                                             as cpm_usd,

        case
            when b.link_clicks > 0
                then round(b.spend_usd / b.link_clicks, 4)
        end                                                             as cpc_usd,

        case
            when b.conversions > 0
                then round(b.spend_usd / b.conversions::float, 4)
        end                                                             as cpa_usd,

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
