SELECT
    user,
    SUM(flares) AS total_flares
FROM
    (
        SELECT user, flares FROM {{ ref('int_flares_by_lp')}}

        UNION ALL
        SELECT user, flares FROM {{ ref('int_flares_by_token_balance') }}

        UNION ALL
        SELECT user, flares FROM {{ ref('int_flares_by_expo_lp') }}
      

    )
GROUP BY user
ORDER BY 2 DESC