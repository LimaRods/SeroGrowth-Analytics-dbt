WITH lp_flares AS (
    SELECT 
        user,
        SUM(flares) AS pools
    FROM {{ ref('int_flares_by_lp') }}
    GROUP BY user
),

token_flares AS (
    SELECT 
        user,   
        SUM(CASE WHEN symbol = 'USX' THEN flares ELSE 0 END)                AS usx,
        SUM(CASE WHEN symbol = 'eUSX' THEN flares ELSE 0 END)               AS eusx,
        SUM(CASE WHEN symbol = 'YT-eUSX-11MAR26' THEN flares ELSE 0 END)     AS yt_eusx,
        SUM(CASE WHEN symbol = 'YT-USX-09FEB26' THEN flares ELSE 0 END)      AS yt_usx
    FROM {{ ref('int_flares_by_token_balance') }}
    GROUP BY user
),

expo_flares AS (
    SELECT 
        user,   
        SUM(CASE WHEN symbol = 'ELP-eUSX-11MAR26' THEN flares ELSE 0 END)    AS elp_eusx,
        SUM(CASE WHEN symbol = 'ELP-USX-09FEB26' THEN flares ELSE 0 END)     AS elp_usx
    FROM {{ ref('int_flares_by_expo_lp') }}
    GROUP BY user
),


all_users AS (
    SELECT user FROM lp_flares
    UNION
    SELECT user FROM token_flares
    UNION
    SELECT user FROM expo_flares
)

SELECT
    u.user,
     -- TOTAL FLARES (ALL PRODUCTS)
        COALESCE(lp.pools, 0)
    + COALESCE(t.usx, 0)
    + COALESCE(t.eusx, 0)
    + COALESCE(t.yt_eusx, 0)
    + COALESCE(t.yt_usx, 0)
    + COALESCE(e.elp_eusx, 0)
    + COALESCE(e.elp_usx, 0)
        AS total_flares,
    -- LP pools
    COALESCE(lp.pools, 0)        AS pools,

    -- Token balances
    COALESCE(t.usx, 0)           AS usx,
    COALESCE(t.eusx, 0)          AS eusx,
    COALESCE(t.yt_eusx, 0)       AS yt_eusx,
    COALESCE(t.yt_usx, 0)        AS yt_usx,

    -- Exponent LPs
    COALESCE(e.elp_eusx, 0)      AS elp_eusx,
    COALESCE(e.elp_usx, 0)       AS elp_usx

FROM all_users u
LEFT JOIN lp_flares    lp ON u.user = lp.user
LEFT JOIN token_flares t  ON u.user = t.user
LEFT JOIN expo_flares  e  ON u.user = e.user

ORDER BY total_flares DESC