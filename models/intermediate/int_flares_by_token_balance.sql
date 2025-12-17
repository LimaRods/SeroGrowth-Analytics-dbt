WITH registered_users AS (
    SELECT address
    FROM {{ ref('user_addresses') }}
),

blacklisted_users AS (
    SELECT address
    FROM {{ ref('blacklisted_addresses') }}
),

/* 1️⃣ Normalize raw streaks */
base AS (
    SELECT
        user,
        token_mint_address,
        symbol,
        amount,
        start_ts,

        /* cap open streaks at end of yesterday (23:59:59) */
        LEAST(
            COALESCE(end_ts, DATEADD(second, -1, CURRENT_TIMESTAMP())),
            DATEADD(second, -1, DATEADD(day, 1, CURRENT_DATE()))
        ) AS end_ts
    FROM {{ ref('stg_token_balances') }}
    WHERE amount > 0
),

/* 2️⃣ Exclude registered & blacklisted users */
eligible AS (
    SELECT b.*
    FROM base b
    LEFT JOIN registered_users r
        ON b.user = r.address
    LEFT JOIN blacklisted_users bl
        ON b.user = bl.address
    WHERE r.address IS NULL
      AND bl.address IS NULL
      AND b.start_ts < b.end_ts
),

/* 3️⃣ Resolve overlapping threshold streaks */
windowed AS (
    SELECT
        e.*,
        LEAD(e.start_ts) OVER (
            PARTITION BY e.user, e.token_mint_address
            ORDER BY e.start_ts
        ) AS next_start_ts
    FROM eligible e
),

/* 4️⃣ Compute the effective (non-overlapping) window */
effective AS (
    SELECT
        user,
        token_mint_address,
        symbol,
        amount,
        start_ts,

        LEAST(
            end_ts,
            COALESCE(DATEADD(second, -1, next_start_ts), end_ts)
        ) AS effective_end_ts
    FROM windowed
),

/* 5️⃣ Compute FULL DAYS ONLY */
final AS (
    SELECT
        user,
        token_mint_address,
        symbol,
        amount,
        start_ts,
        effective_end_ts,

        FLOOR(
            DATEDIFF(second, start_ts, effective_end_ts) / 86400
        ) AS days_held
    FROM effective
    WHERE effective_end_ts > start_ts
)

SELECT
    user,
    token_mint_address,
    symbol,
    amount,
    start_ts,
    effective_end_ts AS end_ts,
    days_held,

    amount
        * days_held
        * {{ tvl_multiplier('token_mint_address', 'symbol') }}
        AS flares
FROM final
WHERE days_held >= 1
ORDER BY start_ts, user, token_mint_address