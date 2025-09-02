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

-- It doesn't mint or burn  USX
vault_operation_events AS (
    SELECT
        DATE_TRUNC('day', timestamp_ntz) AS date,
        symbol,
        sum(CASE WHEN type = 'TRANSFER_IN_COLLATERAL' THEN amount else 0 end) as daily_mints,
        sum(CASE WHEN type = 'WITHDRAW_FROM_STABLE_DEPOSITORY' THEN amount else 0 end) as daily_redeems,
        sum(
            CASE
                WHEN type = 'TRANSFER_IN_COLLATERAL' then amount 
                WHEN type = 'WITHDRAW_FROM_STABLE_DEPOSITORY' then -amount 
            ELSE 0 
        END
        ) as daily_netflow
    FROM {{ ref('stg_usx_vault') }}
    GROUP BY 1, 2
),

base AS (
    SELECT * FROM usx_vault_events
    UNION ALL
    SELECT * FROM vault_operation_events
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

-- Generate ALL dates independently of events (constant ROWCOUNT, then trim)
all_dates AS (
    SELECT
        DATEADD(day, SEQ4(), db.min_date) AS date
    FROM date_bounds db,
         TABLE(GENERATOR(ROWCOUNT => 20000))  -- ~54 years; increase if needed
    WHERE DATEADD(day, SEQ4(), db.min_date) <= db.max_date
),

-- All tokens seen in the period
all_symbols AS (
    SELECT DISTINCT symbol FROM aggregated
),

-- Full calendar: dates × tokens
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