WITH base AS (
  -- One row per "streak": position amount applies from start_ts until end_ts (or ongoing)
  SELECT
    user,
    symbol,
    market,
    amount,                                    -- already humanized (decimals adjusted) in STG
    DATE(start_timestamp_ntz)        AS start_date,
    DATE(end_timestamp_ntz)          AS end_date,
    COALESCE(DATE(end_timestamp_ntz), CURRENT_DATE()) AS end_date_c  -- inclusive end
  FROM {{ ref('stg_liquidity_expo') }}
  WHERE amount > 0
),

first_position AS (
  -- First day the user had a positive liquidity position
  SELECT
    user,
    symbol,
    market,
    MIN(start_date) AS first_date
  FROM base
  GROUP BY 1,2,3
),

date_bounds AS (
  -- Calendar from earliest first hold to today
  SELECT
    MIN(first_date) AS min_date,
    CURRENT_DATE()  AS max_date
  FROM first_position
),

all_dates AS (
  -- Generate enough rows and trim to the bounds
  SELECT DATEADD(day, n, db.min_date) AS date
  FROM date_bounds db
  JOIN LATERAL (
    SELECT SEQ4() AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 20000))   -- ~54 years; adjust upward if needed
  ) g
  WHERE DATEADD(day, n, db.min_date) <= db.max_date
),

calendar_user_symbol_market AS (
  -- Full grid: every date × (user, symbol, market) AFTER that pair’s first day
  SELECT
    d.date,
    p.user,
    p.symbol,
    p.market
  FROM all_dates d
  CROSS JOIN first_position p
  WHERE d.date >= p.first_date
),

daily_positions AS (
  -- For each day, pick the MAX amount among active streaks for that user+symbol+market
  SELECT
    c.date,
    c.user,
    c.symbol,
    c.market,
    b.amount AS position_amount
  FROM calendar_user_symbol_market c
  LEFT JOIN base b
    ON b.user   = c.user
   AND b.symbol = c.symbol
   AND b.market = c.market
   AND c.date BETWEEN b.start_date AND b.end_date_c
  QUALIFY ROW_NUMBER() OVER (PARTITION BY c.date, c.user, c.symbol, c.market ORDER BY b.start_date DESC) = 1
)

SELECT
  date,
  user,
  symbol,
  market,
  COALESCE(position_amount, 0) AS position_amount
FROM daily_positions
ORDER BY date, user, symbol, market