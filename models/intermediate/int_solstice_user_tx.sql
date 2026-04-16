WITH base AS (
    SELECT 
        timestamp_ntz,
        signature,
        'Solstice' AS protocol,
        'Yield Vault (eUSX)' AS venue,
        user,
        user_shares,
        symbol,
        amount,
        type
    FROM {{ ref("stg_yield_vault")}}
    
),

referrals AS (
     SELECT
    *
    FROM {{ ref('int_referrals') }}
),

seasons AS (
    SELECT *
    FROM {{ ref("dim_seasons") }}
)

SELECT
    b.*,
    r.referral_code,
    s.season,
    CASE 
        WHEN r.referral_code IS NOT NULL THEN 1
        ELSE 0
    END AS referral_activated
FROM base b
LEFT JOIN referrals r
    ON b.user = r.referred_address
   AND b.timestamp_ntz >= r.created_at
LEFT JOIN seasons s
    ON  b.timestamp_ntz >= s.start_date
    AND  b.timestamp_ntz <= s.end_date