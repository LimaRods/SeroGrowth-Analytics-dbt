with
base as (
    select
        date,
        user,
        symbol,
        market,
        coalesce(position_amount, 0) as position_amount
    from {{ ref("int_daily_expo_positions") }}
),

-- 1) Flag whether the user is holding liquidity on that day
flags as (
    select
        *,
        case when position_amount > 1e-9 then 1 else 0 end as is_holding
    from base
),

-- 2) Build a "reset id": increments each time we see a non-holding day
with_resets as (
    select
        *,
        sum(case when is_holding = 0 then 1 else 0 end) over (
            partition by user, symbol, market
            order by date
            rows between unbounded preceding and current row
        ) as reset_id
    from flags
),

-- 3) For holding days, streak = row_number within reset_id group
holding_days as (
    select
        date,
        user,
        symbol,
        market,
        position_amount,
        case
            when is_holding = 1
            then row_number() over (
                partition by user, symbol, market, reset_id
                order by date
            )
            else 0
        end as holding_streak_days
    from with_resets
),

points_calculation as (
    select
        date,
        user,
        'Exponent' as protocol,
        symbol,
        market,
        position_amount,
        {{ base_multiplier("symbol") }} as base_mult,
        position_amount * {{ base_multiplier("symbol") }} as base_points,
        {{ loyalty_multiplier("holding_streak_days") }} as loyalty_mult,
        {{ base_multiplier("symbol") }}
        * {{ loyalty_multiplier("holding_streak_days") }} as overall_mult_nocap,
        case
            when
                {{ base_multiplier("symbol") }}
                * {{ loyalty_multiplier("holding_streak_days") }}
                > 10
            then 10
            else
                {{ base_multiplier("symbol") }}
                * {{ loyalty_multiplier("holding_streak_days") }}
        end as overall_mult,
        {{ loyalty_tier_label("holding_streak_days") }} as loyalty_label,
        holding_streak_days
    from holding_days
)

select
    *,
    base_points * overall_mult as total_points
from points_calculation
order by date, user, symbol, market