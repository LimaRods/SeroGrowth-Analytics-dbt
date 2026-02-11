{{
    config(
        materialized = 'view'
    )

}}

SELECT
   referral.id,
   referral.created_at,
   referral.referral_code,
   referred.address AS referred_address,
   referral.referred_user_id,
   referrer.address AS referrer_address,
   referral.referrer_user_id
FROM
    {{ ref('stg_referrals') }} referral
LEFT JOIN
    {{ ref('user_addresses') }} referred
    ON referral.referred_user_id = referred.user_id 
LEFT JOIN
     {{ ref('user_addresses') }} referrer
    ON referral.referrer_user_id = referrer.user_id 
