{{
    config(
        materialized = 'table'
    )
}}

WITH referrals_base AS (
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
),

seasons AS (
    SELECT * FROM {{ ref('dim_seasons') }}
)

SELECT
    r.id,
    r.created_at,
    r.referral_code,
    r.referred_address,
    r.referred_user_id,
    r.referrer_address,
    r.referrer_user_id,
    s.season
FROM referrals_base r
LEFT JOIN seasons s
    ON DATE_TRUNC('day', r.created_at) >= s.start_date
    AND DATE_TRUNC('day', r.created_at) <= s.end_date