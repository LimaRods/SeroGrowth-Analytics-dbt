WITH base AS (
  -- One row per "streak": balance >= amount from start_ts until end_ts (or ongoing)
  SELECT
    user,
    symbol,
    token_mint_address,
    amount,                                    -- already humanized (decimals adjusted) in STG
    DATE(start_ts)        AS start_date,
    DATE(end_ts)         AS end_date,
    COALESCE(DATE(end_ts), CURRENT_DATE()) AS end_date_c  -- inclusive end
  FROM {{ ref('stg_token_balances') }}
  -- Optional whitelist (keep if desired)
),

first_hold AS (
  -- First day the user held this token (>0)
  SELECT
    user,
    symbol,
    MIN(start_date) AS first_date
  FROM base
  WHERE amount > 0
  GROUP BY 1,2
),

date_bounds AS (
  -- Calendar from earliest first hold to today
  SELECT
    MIN(first_date) AS min_date,
    CURRENT_DATE()  AS max_date
  FROM first_hold

),

all_dates AS ( 
SELECT
    date_day AS date
FROM
    {{ ref('dim_date')}}
),



calendar_user_token AS (
  -- Full grid: every date × (user, token) AFTER that pair’s first holding day
  SELECT
    d.date,
    p.user,
    p.symbol
  FROM all_dates d
  CROSS JOIN first_hold p
  WHERE d.date >= p.first_date
),

daily_positions AS (
  -- For each day, pick the MAX amount among active streaks for that user+token
  -- (threshold model: the highest active threshold equals the balance that day)
  SELECT
    c.date,
    c.user,
    c.symbol,
    amount AS token_balance
  FROM calendar_user_token c
  LEFT JOIN base b
    ON b.user = c.user
   AND b.symbol = c.symbol
   AND c.date BETWEEN b.start_date AND b.end_date_c
  QUALIFY ROW_NUMBER() OVER (PARTITION BY c.date, c.user, c.symbol ORDER BY b.start_date DESC) = 1
)


SELECT
  date,
  user,
  symbol,
  COALESCE(token_balance, 0) AS token_balance
FROM daily_positions


ORDER BY date, user, symbol
