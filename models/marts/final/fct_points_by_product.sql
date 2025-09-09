SELECT
    *
FROM (

    SELECT
        date,
        user,
        protocol,
        symbol,
        symbol AS product_symbol,
        base_points,
        total_points AS overall_points

    FROM
        {{  ref('fct_token_bal_points')}}

    UNION ALL

    SELECT
        date,
        user,
        protocol,
        pool_symbol AS symbol,
        protocol || ': ' || symbol AS product_symbol,
        base_points,
        total_points AS overall_points

    FROM
        {{  ref('fct_lp_points')}}
)

ORDER BY date, product_symbol, overall_points DESC



