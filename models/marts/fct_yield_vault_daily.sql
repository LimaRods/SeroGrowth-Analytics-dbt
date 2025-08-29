with base as (
    select
        date_trunc('day', timestamp_ntz) as date,
        symbol,
        sum(case when type = 'LOCK' then amount else 0 end) as daily_mints,
        sum(case when type = 'UNLOCK' then amount else 0 end) as daily_redeems,
        sum(
            CASE
                WHEN type = 'LOCK' then amount 
                WHEN type = 'UNLOCK' then -amount 
            ELSE 0 
        END
        ) as daily_netflow
    from {{ ref('int_yield_vault') }}
    group by 1,2
),

-- all dates × tokens
date_bounds AS (
    SELECT 
        MIN(date) AS min_date,
        MAX(date) AS max_date
    FROM base
),

calendar_token AS (
    SELECT 
        DATEADD(day, seq4(), db.min_date) AS date,
        t.symbol
    FROM date_bounds db,
         TABLE(GENERATOR(ROWCOUNT => 1000)) -- <-- generate more than enough days
         AS seq
    CROSS JOIN (
        SELECT DISTINCT symbol
        FROM base
    ) t
    WHERE DATEADD(day, seq4(), db.min_date) <= db.max_date -- filter to actual range
),

daily as (
    select
        c.date,
        c.symbol,
        coalesce(b.daily_mints, 0) as daily_mints,
        coalesce(b.daily_redeems, 0) as daily_redeems,
        coalesce(b.daily_netflow, 0) as daily_netflow
    from calendar_token c
    left join base b
        on c.date = b.date and c.symbol = b.symbol
),

-- Add cumulative metrics
final as (
    select
        date,
        symbol,
        daily_mints AS daily_deposits,
        daily_redeems AS daily_withdrawals,
        sum(daily_mints) over (partition by symbol order by date) as cumulative_deposits,
        sum(daily_redeems) over (partition by symbol order by date ) as cumulative_withdrawals,
        sum(daily_netflow) over (partition by symbol order by date ) as total_tokens_locked
    from daily
)

select *
from final
order by date, symbol