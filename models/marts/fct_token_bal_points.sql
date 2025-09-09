WITH base AS (
  SELECT
    date,
    user,                 
    symbol,
    COALESCE(token_balance, 0) AS token_balance
  FROM {{ ref('int_daily_token_balance') }}
),

-- 1) Flag whether the user is holding on that day
flags AS (
  SELECT
      *,
      CASE WHEN token_balance > 1e-9 THEN 1 ELSE 0 END AS is_holding
  FROM base
),

-- 2) Build a "reset id": it increases by 1 each time we see a non-holding day.
--    For any consecutive run of holding days, this id stays constant.
with_resets AS (
  SELECT
      *,
      SUM(CASE WHEN is_holding = 0 THEN 1 ELSE 0 END)
        OVER (PARTITION BY user, symbol ORDER BY date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS reset_id
  FROM flags
),

-- 3) For holding days, the streak is the row_number within its current reset_id group.
--    For non-holding days, streak = 0.
holding_days AS (
    SELECT
        date,
        user,
        symbol,
        token_balance,
        CASE
        WHEN is_holding = 1 THEN
            ROW_NUMBER() OVER (PARTITION BY user, symbol, reset_id ORDER BY date)
        ELSE 0
        END AS holding_streak_days
    FROM with_resets
),

points_calculation AS (
    SELECT
      date,
      user,
      'Solstice' AS protocol,
      symbol,
      token_balance,
      holding_streak_days,
      {{ base_multiplier('Solstice', symbol) }} AS base_mult,
      token_balance * {{ base_multiplier('Solstice', symbol) }} AS base_points,
      {{ loyalty_multiplier('holding_streak_days') }} AS loyalty_mult,
      {{ base_multiplier('Solstice', symbol) }} *  {{ loyalty_multiplier('holding_streak_days') }} AS overall_mult_nocap, --Add more multipliers
      CASE
        WHEN {{ base_multiplier('Solstice', symbol) }} *  {{ loyalty_multiplier('holding_streak_days') }} > 10
        THEN 10 ELSE {{ base_multiplier('Solstice', symbol) }} *  {{ loyalty_multiplier('holding_streak_days') }}
    END AS overall_mult, --Add more multipliers
      {{ loyalty_tier_label('holding_streak_days') }} AS loyalty_label

     
    FROM
        holding_days
)

SELECT
    *,
    base_points * overall_mult AS total_points, 
FROM
    points_calculation
ORDER BY date, user, symbol