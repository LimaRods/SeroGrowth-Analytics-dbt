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
  FROM {{ ref('stg_liquidity_cpmm') }}
  ),

first_lp_date AS (
  SELECT
    user,
    pool_symbol,
    pool_type,
    MIN(start_date) AS first_date
  FROM base
  WHERE amount_x > 0 OR amount_y > 0
  GROUP BY 1, 2, 3
),

date_bounds AS (
  SELECT
    MIN(first_date) AS min_date,
    CURRENT_DATE()  AS max_date
  FROM first_lp_date
),

all_dates AS (
  SELECT DATEADD(day, n, db.min_date) AS date
  FROM date_bounds db
  JOIN LATERAL (
    SELECT SEQ4() AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 20000))
  ) g
  WHERE DATEADD(day, n, db.min_date) <= db.max_date
),

calendar_user_pool AS (
  SELECT
    d.date,
    p.user,
    p.pool_symbol,
    p.pool_type,
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
    MAX(b.amount_x)  AS amount_x,
    MAX(b.amount_y)  AS amount_y
    --MAX(b.lp_amount) AS lp_amount
  FROM calendar_user_pool c
  LEFT JOIN base b
    ON b.user = c.user
   AND b.pool_symbol = c.pool_symbol
   AND c.date BETWEEN b.start_date AND b.end_date_c
  GROUP BY 1, 2, 3, 4
)

SELECT
 date,
  user,
  pool_type,
  pool_symbol,
  COALESCE(amount_x, 0)  AS amount_x,
  COALESCE(amount_y, 0)  AS amount_y
  --COALESCE(lp_amount, 0) AS lp_amount
FROM daily_lp
ORDER BY date, user, pool_symbol