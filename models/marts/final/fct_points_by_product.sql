SELECT
    *
FROM (

    SELECT
        date,
        user,
        protocol,
        symbol,
        symbol AS product_symbol,
        token_balance,
        null AS amount_x,
        null AS amount_y,
        token_balance AS total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days

    FROM
        {{  ref('fct_token_bal_points')}}

    UNION ALL

    SELECT
        date,
        user,
        protocol,
        pool_symbol AS symbol,
        protocol || ': ' || symbol AS product_symbol,
        null AS token_balance,
        amount_x,
        amount_y,
        total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days

    FROM
        {{  ref('fct_lp_points')}}
)

ORDER BY date, product_symbol, overall_points DESC



