WITH points AS (
    SELECT
        date,
        user,
        protocol,
        symbol,
        symbol AS product_symbol,
        token_balance,
        null AS amount_x,
        null AS amount_y,
        token_balance AS total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_token_bal_points')}}

    UNION ALL

    SELECT
        date,
        user,
        protocol,
        pool_symbol AS symbol,
        protocol || ': ' || symbol AS product_symbol,
        null AS token_balance,
        amount_x,
        amount_y,
        total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_lp_points')}}

    UNION ALL

    SELECT
        date,
        user,
        protocol,
        symbol,
        protocol || ': ' || symbol AS product_symbol,
        position_amount AS token_balance,
        null AS amount_x,
        null AS amount_y,
        position_amount AS total_liquidity,
        base_mult,
        base_points,
        overall_mult_nocap,
        overall_mult,
        total_points AS overall_points,
        holding_streak_days
    FROM {{ ref('fct_expo_positions_points')}}
),

referrals AS (
    SELECT
       referral.id,
       referral.created_at,
       referral.referral_code,
       referred.address AS referred_address,
       referral.referred_user_id,
       referrer.address AS referrer_address,
       referral.referrer_user_id
    FROM {{ ref('stg_referrals') }} referral
    LEFT JOIN {{ ref('user_addresses') }} referred
        ON referral.referred_user_id = referred.user_id 
    LEFT JOIN {{ ref('user_addresses') }} referrer
        ON referral.referrer_user_id = referrer.user_id 
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
   AND p.date >= DATE(r.created_at)
ORDER BY p.date, p.product_symbol, p.overall_points DESC