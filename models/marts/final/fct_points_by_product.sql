{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['date', 'user', 'protocol', 'product_symbol', 'product_address']
  )
}}

WITH watermark AS (
  SELECT
    DATEADD(day,-7,COALESCE(MAX(date), TO_DATE('1900-01-01'))) AS min_date
  FROM {{ this }}
),

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
    {% if is_incremental() %}
    WHERE date >= (SELECT min_date FROM watermark)
    {% endif %}

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
    {% if is_incremental() %}
    WHERE date >= (SELECT min_date FROM watermark)
    {% endif %}

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
    {% if is_incremental() %}
    WHERE date >= (SELECT min_date FROM watermark)
    {% endif %}

),

referrals AS (
    SELECT *
    FROM {{ ref('int_referrals') }}
    QUALIFY ROW_NUMBER() OVER(PARTITION BY referred_address ORDER BY created_at ASC) = 1
)

SELECT
    p.*,
    r.referral_code,
    CASE
        WHEN r.referral_code IS NOT NULL THEN 1
        ELSE 0
    END AS referral_activated
FROM points p
LEFT JOIN referrals r
    ON p.user = r.referred_address
   AND p.date >= TO_DATE(r.created_at)
WHERE
    p.total_liquidity > 0
