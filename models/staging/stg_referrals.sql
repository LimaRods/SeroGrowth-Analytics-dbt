SELECT
    id,
   created_at,
   referral_code,
   referred_user_id,
   referrer_user_id,
   status
FROM
    {{ source('internal', 'pending_referral_rewards') }}