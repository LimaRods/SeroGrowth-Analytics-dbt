{{
    config(
        materialized = 'incremental',
        unique_key = ['date', 'user', 'protocol', 'symbol', 'token_mint_address'],
        incremental_strategy='merge'
    )

}}

with
    base as (
        select
            date, user, symbol, token_mint_address, coalesce(token_balance, 0) as token_balance
        from
            {{ ref("int_daily_token_balance") }}
        {% if is_incremental() %}

        where
            date >= (SELECT DATEADD(day,-7,COALESCE(MAX(date), TO_DATE('1900-01-01'))) FROM {{ this }})

        {% endif %}

    ),

    -- 1) Flag whether the user is holding on that day
    flags as (
        select *, case when token_balance > 1e-9 then 1 else 0 end as is_holding
        from base
    ),

    -- 2) Build a "reset id": it increases by 1 each time we see a non-holding day.
    -- For any consecutive run of holding days, this id stays constant.
    with_resets as (
        select
            *,
            sum(case when is_holding = 0 then 1 else 0 end) over (
                partition by user, symbol, token_mint_address
                order by date
                rows between unbounded preceding and current row
            ) as reset_id
        from flags
    ),

    -- 3) For holding days, the streak is the row_number within its current reset_id
    -- group.
    -- For non-holding days, streak = 0.
    holding_days as (
        select
            date,
            user,
            symbol,
            token_balance,
             token_mint_address,
            case
                when is_holding = 1
                then
                    row_number() over (
                        partition by user, symbol, token_mint_address, reset_id order by date
                    )
                else 0
            end as holding_streak_days
        from with_resets
    ),

    points_calculation as (
        select
            date,
            user,
            'Solstice' as protocol,
            symbol,
            token_balance,
            token_mint_address,
            {{ base_multiplier("symbol") }} as base_mult,
            token_balance * {{ base_multiplier("symbol") }} as base_points,
            {{ loyalty_multiplier("holding_streak_days") }} as loyalty_mult,
            {{ base_multiplier("symbol") }}
            * {{ loyalty_multiplier("holding_streak_days") }} as overall_mult_nocap,  -- Add more multipliers
            case
                when
                    {{ base_multiplier("symbol") }}
                    * {{ loyalty_multiplier("holding_streak_days") }}
                    > 10
                then 10
                else
                    {{ base_multiplier("symbol") }}
                    * {{ loyalty_multiplier("holding_streak_days") }}
            end as overall_mult,  -- Add more multipliers
            {{ loyalty_tier_label("holding_streak_days") }} as loyalty_label,
            holding_streak_days

        from holding_days
    )

select
    *,
    base_points * overall_mult as total_points
from points_calculation