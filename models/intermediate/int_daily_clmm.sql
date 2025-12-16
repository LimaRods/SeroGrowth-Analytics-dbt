WITH base AS (
  SELECT
    user,
    pool_symbol,
    pool_address,
    pool_type,
    amount_x,
    amount_y,
    DATE(start_timestamp_ntz) AS start_date,
    DATE(end_timestamp_ntz)   AS end_date,
    COALESCE(DATE(end_timestamp_ntz), CURRENT_DATE()) AS end_date_c
  FROM {{ ref('stg_liquidity_clmm') }}
  ),

first_lp_date AS (
  SELECT
    user,
    pool_symbol,
    pool_address,
    pool_type,
    MIN(start_date) AS first_date
  FROM base
  WHERE amount_x > 0 OR amount_y > 0
  GROUP BY 1, 2, 3, 4
),

date_bounds AS (
  SELECT
    MIN(first_date) AS min_date,
    CURRENT_DATE()  AS max_date
  FROM first_lp_date

),

all_dates AS (
SELECT
    date_day AS date
FROM
    {{ ref('dim_date')}}
    
),

calendar_user_pool AS (
  SELECT
    d.date,
    p.user,
    p.pool_symbol,
    p.pool_type,
    p.pool_address
  FROM all_dates d
  CROSS JOIN first_lp_date p
  WHERE d.date >= p.first_date


),

daily_lp AS (
  SELECT
    c.date,
    c.user,
    c.pool_type,
    c.pool_symbol,
    c.pool_address,
    b.amount_x,
    b.amount_y
    --MAX(b.lp_amount) AS lp_amount
  FROM calendar_user_pool c
  LEFT JOIN base b
    ON b.user = c.user
   AND b.pool_address = c.pool_address
   AND c.date BETWEEN b.start_date AND b.end_date_c
 QUALIFY ROW_NUMBER() OVER (PARTITION BY c.date, c.user, c.pool_type,c.pool_symbol, c.pool_address ORDER BY b.start_date DESC) = 1
 
)


SELECT
 date,
  user,
  pool_type,
  pool_address,
  pool_symbol,
  COALESCE(amount_x, 0)  AS amount_x,
  COALESCE(amount_y, 0)  AS amount_y
  --COALESCE(lp_amount, 0) AS lp_amount
FROM daily_lp
ORDER BY date, user, pool_symbol, pool_address
