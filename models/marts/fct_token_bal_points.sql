with
    base as (
        select
            date, user, symbol, token_mint_address, coalesce(token_balance, 0) as token_balance
        from
            {{ ref("int_daily_token_balance") }}
    ),

    flags as (
        select *, case when token_balance > 1e-9 then 1 else 0 end as is_holding
        from base
    ),

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
    ),

    seasons as (
        select *
        from {{ ref("dim_seasons") }}
    ),

    final as (
        select
            pc.*,
            pc.base_points * pc.overall_mult as total_points,
            s.season
        from points_calculation pc
        left join seasons s
            on pc.date >= s.start_date
            and pc.date <= s.end_date
    )

select *
from final