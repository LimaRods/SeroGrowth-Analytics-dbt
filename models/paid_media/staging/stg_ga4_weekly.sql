with source as (
    select * from {{ source('paid_media', 'fct_ga4_weekly') }}
)

select
    id,
    client_id,
    week_date,
    utm_source,
    utm_source_medium,
    utm_campaign,
    utm_content,
    -- Traffic Acquisition
    ga4_sessions,
    engaged_sessions,
    engagement_rate,
    avg_engagement_time                 as avg_session_time,   -- downstream-compatible name
    events_per_session,
    event_count,
    key_events,
    session_key_event_rate,
    total_revenue,
    -- User Acquisition
    ga4_users,
    new_users,
    returning_users,
    engaged_sessions_per_active_user,
    user_key_event_rate
from source
