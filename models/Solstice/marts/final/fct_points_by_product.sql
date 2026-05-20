{{
  config(
    materialized = 'table'
  )
}}

WITH

points AS (

    -- Token balances snapshot
    SELECT
        date,
        user,
        protocol,
        symbol,
        symbol AS product_symbol,
        token_mint_address AS product_address,
        token_balance,
        NULL AS amount_x,
        NULL AS amount_y,
        token_balance AS total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_token_bal_points') }}

    UNION ALL

    -- LP positions snapshot
    SELECT
        date,
        user,
        protocol,
        pool_symbol AS symbol,
        protocol || ': ' || pool_symbol AS product_symbol,
        pool_address AS product_address,
        NULL AS token_balance,
        amount_x,
        amount_y,
        total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_lp_points') }}

    UNION ALL

    -- Exponent positions snapshot
    SELECT
        date,
        user,
        protocol,
        symbol,
        protocol || ': ' || symbol AS product_symbol,
        market AS product_address,
        position_amount AS token_balance,
        NULL AS amount_x,
        NULL AS amount_y,
        position_amount AS total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_expo_positions_points') }}

),

referrals AS (
    SELECT *
    FROM {{ ref('int_referrals') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY referred_address ORDER BY created_at ASC) = 1
),

-- Season enrichment
seasons AS (
    SELECT * FROM {{ ref('dim_seasons') }}
)

SELECT
    p.date,
    p.user,
    p.protocol,
    p.symbol,
    p.product_symbol,
    p.product_address,
    p.token_balance,
    p.amount_x,
    p.amount_y,
    p.total_liquidity,
    p.base_mult,
    p.base_points,
    p.overall_mult_nocap,
    p.overall_mult,
    p.overall_points,
    p.holding_streak_days,
    r.referral_code,
    CASE
        WHEN r.referral_code IS NOT NULL THEN 1
        ELSE 0
    END AS referral_activated,
    s.season
FROM points p
LEFT JOIN referrals r
    ON p.user = r.referred_address
   AND p.date >= TO_DATE(r.created_at)
LEFT JOIN seasons s
    ON p.date >= s.start_date
    AND p.date <= s.end_date
WHERE
    p.total_liquidity > 0