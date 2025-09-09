SELECT
    *
FROM (

    SELECT
        date,
        user,
        protocol,
        symbol,
        symbol AS product_symbol,
        points_with_loyalty AS overall_points

    FROM
        {{  ref('fct_token_bal_points')}}

    UNION ALL

    SELECT
        date,
        user,
        protocol,
        pool_symbol AS symbol,
        protocol || ': ' || symbol AS product_symbol,
        points_with_loyalty AS overall_points

    FROM
        {{  ref('fct_lp_points')}}
)

ORDER BY date, product_symbol, overall_points DESC



