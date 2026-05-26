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
        utm_campaign,
        week_date,
        sum(ga4_sessions)     as ga4_sessions,
        sum(ga4_users)        as ga4_users,
        sum(engaged_sessions) as engaged_sessions,
        sum(key_events)       as key_events,
        case when sum(ga4_sessions) > 0
             then round(sum(engaged_sessions) / sum(ga4_sessions)::float, 4)
        end                   as engagement_rate
    from {{ ref('stg_ga4_weekly') }}
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

        /* Derived metrics */
        case when p.impressions > 0 then round(p.clicks / p.impressions::float, 6) end      as ctr,
        case when p.impressions > 0 then round(p.spend_usd * 1000.0 / p.impressions, 4) end as cpm_usd,
        case when p.clicks       > 0 then round(p.spend_usd / p.clicks, 4) end              as cpc_usd,
        case when p.conversions  > 0 then round(p.spend_usd / p.conversions::float, 4) end   as cpa_usd,

        /* GA4 attribution (campaign grain) */
        g.ga4_sessions,
        g.ga4_users,
        g.engaged_sessions,
        g.key_events,
        g.engagement_rate,

        p.data_quality_flag
    from paid_agg p
    left join ga4 g
        on  g.client_id    = p.client_id
        and g.utm_campaign = p.utm_campaign
        and g.week_date    = p.week_date
    left join clients cl
        on cl.client_id = p.client_id
)

select * from final
