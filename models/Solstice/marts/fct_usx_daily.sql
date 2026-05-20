WITH usx_vault_events as (
    select
        DATE_TRUNC('day', timestamp_ntz) AS date,
        symbol,
        sum(case when type = 'CONFIRM_MINT' then amount else 0 end) as daily_mints,
        sum(case when type = 'CONFIRM_REDEEM' then amount else 0 end) as daily_redeems,
        sum(
            CASE
                WHEN type = 'CONFIRM_MINT' then amount 
                WHEN type = 'CONFIRM_REDEEM' then -amount 
            ELSE 0 
        END
        ) as daily_netflow
    from {{ ref('stg_usx_mint_redeem') }}
    group by 1,2
),

base AS (
    SELECT * FROM usx_vault_events
    --UNION ALL
    --SELECT * FROM vault_operation_events
),

aggregated AS (
    SELECT
        date,
        symbol,
        SUM(daily_mints) AS daily_mints,
        SUM(daily_redeems) AS daily_redeems,
        SUM(daily_netflow) AS daily_netflow
    FROM base
    GROUP BY 1, 2
),

date_bounds AS (
    SELECT
        MIN(date) AS min_date,
        MAX(CURRENT_DATE()) AS max_date
    FROM aggregated
),

all_dates AS (
    SELECT
        DATEADD(day, SEQ4(), db.min_date) AS date
    FROM date_bounds db,
         TABLE(GENERATOR(ROWCOUNT => 20000))
    WHERE DATEADD(day, SEQ4(), db.min_date) <= db.max_date
),

all_symbols AS (
    SELECT DISTINCT symbol FROM aggregated
),

calendar_token AS (
    SELECT d.date, s.symbol
    FROM all_dates d
    CROSS JOIN all_symbols s
),

daily AS (
    SELECT
        c.date,
        c.symbol,
        COALESCE(a.daily_mints, 0) AS daily_mints,
        COALESCE(a.daily_redeems, 0) AS daily_redeems,
        COALESCE(a.daily_netflow, 0) AS daily_netflow
    FROM calendar_token c
    LEFT JOIN aggregated a
        ON c.date = a.date AND c.symbol = a.symbol
),

final as (
    select
        date,
        symbol,
        daily_mints AS daily_deposits,
        daily_redeems AS daily_withdrawals,
        sum(daily_mints) over (partition by symbol order by date) as cumulative_deposits,
        sum(daily_redeems) over (partition by symbol order by date) as cumulative_withdrawals,
        sum(daily_netflow) over (partition by symbol order by date) as total_tokens_locked
    from daily
),

-- Season enrichment
seasons as (
    select * from {{ ref('dim_seasons') }}
)

select
    f.date,
    f.symbol,
    f.daily_deposits,
    f.daily_withdrawals,
    f.cumulative_deposits,
    f.cumulative_withdrawals,
    f.total_tokens_locked,
    s.season
from final f
left join seasons s
    on f.date >= s.start_date
    and f.date <= s.end_date
order by f.date, f.symbol