{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'signature'

    )

}}

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
    {% if is_incremental() %}
        where timestamp_ntz >= (SELECT DATEADD(day,-1,COALESCE(MAX(timestamp_ntz), TO_DATE('1900-01-01'))) FROM {{ this }})
    {% endif %}
),

referrals AS (
     SELECT
    *
    FROM {{ ref('int_referrals') }}
)

SELECT
    b.*,
    r.referral_code,
    CASE 
        WHEN r.referral_code IS NOT NULL THEN 1
        ELSE 0
    END AS referral_activated
FROM base b
LEFT JOIN referrals r
    ON b.user = r.referred_address
   AND b.timestamp_ntz >= r.created_at