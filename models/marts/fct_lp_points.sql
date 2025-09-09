WITH pools AS (
  SELECT
      date,
      user                           AS user,
      pool_type,
      pool_symbol,
      amount_x,
      amount_y,
      NULL::float                      AS lp_amount,
      (amount_x + amount_y)            AS total_liquidity
  FROM {{ ref('int_daily_clmm') }}

  UNION ALL

  SELECT
      date,
      user                           AS user,
      pool_type,
      pool_symbol,
      NULL::float                      AS amount_x,
      NULL::float                      AS amount_y,
      lp_amount,
      lp_amount                        AS total_liquidity
  FROM {{ ref('int_daily_cpmm') }}
),

with_protocol AS (
  SELECT
      date,
      user,
      pool_type,
      CASE
        WHEN pool_type = 'ORCA_WHIRLPOOL' THEN 'Orca'
        WHEN pool_type = 'RAYDIUM_CLMM'   THEN 'Raydium'
        WHEN pool_type = 'METEORA_DLMM'   THEN 'Meteora'
        WHEN pool_type = 'RAYDIUM_CPMM'   THEN 'Raydium'
        ELSE 'Unknown'
      END AS protocol,
      pool_symbol,
      amount_x,
      amount_y,
      lp_amount,
      COALESCE(total_liquidity, 0) AS total_liquidity
  FROM pools
),

flags AS (
  SELECT
      *,
      CASE WHEN total_liquidity > 1e-9 THEN 1 ELSE 0 END AS is_holding
  FROM with_protocol
),

with_resets AS (
  SELECT
      *,
      SUM(CASE WHEN is_holding = 0 THEN 1 ELSE 0 END)
        OVER (
          PARTITION BY user, protocol, pool_symbol
          ORDER BY date
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS reset_id
  FROM flags
),

holding_days AS (
  SELECT
      date,
      user,
      protocol,
      pool_type,
      pool_symbol,
      amount_x,
      amount_y,
      lp_amount,
      total_liquidity,
      CASE
        WHEN is_holding = 1 THEN
          ROW_NUMBER() OVER (
            PARTITION BY user, protocol, pool_symbol, reset_id
            ORDER BY date
          )
        ELSE 0
      END AS holding_streak_days
  FROM with_resets
),

points_calculation AS (
  SELECT
      date,
      user,
      protocol,
      pool_type,
      pool_symbol,
      amount_x,
      amount_y,
      lp_amount,
      total_liquidity,

      -- multipliers & points
      {{ base_multiplier('pool_symbol') }}                                      AS base_mult,
      total_liquidity * {{ base_multiplier('pool_symbol') }}                    AS base_points,
       {{ loyalty_multiplier('holding_streak_days') }}                         AS loyalty_mult,
       {{ base_multiplier('pool_symbol') }} *  {{ loyalty_multiplier('holding_streak_days') }} AS overall_mult_nocap, --Add more multipliers
      CASE
        WHEN {{ base_multiplier('pool_symbol') }} *  {{ loyalty_multiplier('holding_streak_days') }} > 10
        THEN 10 ELSE {{ base_multiplier('pool_symbol') }} *  {{ loyalty_multiplier('holding_streak_days') }}
    END AS overall_mult, --Add more multipliers
     
      {{ loyalty_tier_label('holding_streak_days') }}                                      AS loyalty_label
  FROM holding_days
)

SELECT 
*,
base_points * overall_mult AS total_points
FROM
    points_calculation
ORDER BY date, user, protocol, pool_symbol