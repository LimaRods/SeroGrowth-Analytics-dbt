with source as (
    select * from {{ source('paid_media', 'fct_ga4_weekly') }}
),

campaigns as (
    select * from {{ source('paid_media', 'campaigns_ga4') }}
),

joined as (
    select
        f.id,
        f.ga4_campaign_id,
        c.client_id,
        c.utm_source,
        c.utm_medium,
        c.utm_campaign,
        f.utm_content,
        c.linked_platform_campaign_id,
        c.linked_channel_id,
        f.week_date,
        f.ga4_sessions,
        f.ga4_users,
        f.engaged_sessions,
        f.avg_session_time,
        f.key_events,
        f.engagement_rate
    from source f
    left join campaigns c
        on c.ga4_campaign_id = f.ga4_campaign_id
),

final as (
    select * from joined
)

select * from final
