/* dim_budget — budget per ad group / ad set, per client + campaign, with a
   separate budget column per channel (NULL for the channels a row isn't from).
     X        → x_total_budget       ('Ad group total budget', a TOTAL budget)
     LinkedIn → daily_linkedin_budget ('Daily Budget', a DAILY budget)
     Google   → google_total_budget   (placeholder — the Google export preset has
                no budget column today, so it is always NULL until one is added)
   Budget is a property of the ad group/ad set (not time-varying), so we take
   MAX across the loaded weeks per unit. Grain: one row per
   (channel_id, client_id, campaign_id, ad_group_id). Budget is intentionally
   kept OUT of the metric marts and lives only here. */

with x as (
    select
        'x_ads'                            as channel_id,
        client_id,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,
        currency_code,
        max(ad_group_total_budget)         as x_total_budget,
        cast(null as number(12,2))         as daily_linkedin_budget,
        cast(null as number(12,2))         as google_total_budget
    from {{ ref('stg_x_weekly') }}
    where ad_group_total_budget is not null
    group by 1, 2, 3, 4, 5, 6, 7
),

linkedin as (
    select
        'linkedin_ads'                     as channel_id,
        client_id,
        campaign_id,
        campaign_name,
        ad_set_id                          as ad_group_id,
        ad_set_name                        as ad_group_name,
        currency_code,
        cast(null as number(12,2))         as x_total_budget,
        max(ad_set_daily_budget)           as daily_linkedin_budget,
        cast(null as number(12,2))         as google_total_budget
    from {{ ref('stg_linkedin_daily') }}
    where ad_set_daily_budget is not null
    group by 1, 2, 3, 4, 5, 6, 7
),

unioned as (
    select * from x
    union all
    select * from linkedin
),

clients as (
    select client_id, client_name from {{ source('paid_media', 'clients') }}
),

final as (
    select
        u.channel_id,
        u.client_id,
        cl.client_name,
        u.campaign_id,
        u.campaign_name,
        u.ad_group_id,
        u.ad_group_name,
        u.x_total_budget,
        u.daily_linkedin_budget,
        u.google_total_budget,
        u.currency_code
    from unioned u
    left join clients cl
        on cl.client_id = u.client_id
)

select * from final
