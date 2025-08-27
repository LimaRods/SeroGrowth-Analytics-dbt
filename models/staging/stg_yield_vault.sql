SELECT
    id,
    signature,
    timestamp_ntz,
    user,
    asset_mint,
    CASE
        WHEN type = 'LOCK' THEN amount
        ELSE -1 * amount 
    END AS amount,
    type,
FROM
    {{ source("internal","yield_vault") }}
