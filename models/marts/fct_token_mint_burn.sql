with base as (
    select
        date_trunc('day', timestamp_ntz) as date,
        symbol,
        sum(case when type = 'MINT' then amount else 0 end) as daily_mints,
        sum(case when type = 'BURN' then amount else 0 end) as daily_burns,
        sum(
            CASE
                WHEN type = 'MINT' then amount 
                WHEN type = 'BURN' then -amount 
            ELSE 0 
        END
        ) as daily_supply
    from {{ ref('int_token_mint_burn') }}
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
        coalesce(b.daily_burns, 0) as daily_burns,
        coalesce(b.daily_supply, 0) as supply
    from calendar_token c
    left join base b
        on c.date = b.date and c.symbol = b.symbol
),

-- Add cumulative metrics
final as (
    select
        date,
        symbol,
        daily_mints,
        daily_burns,
        sum(daily_mints) over (partition by symbol order by date) as cumulative_mints,
        sum(daily_burns) over (partition by symbol order by date ) as cumulative_burns,
        sum(supply) over (partition by symbol order by date ) as total_supply
    from daily
)

select *
from final
order by date, symbol