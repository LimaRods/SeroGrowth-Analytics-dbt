SELECT
    id,
    timestamp_ntz,
    signature,
    from_address AS user,
    mint,
    CASE
        WHEN  type = 'MINT' THEN amount
        ELSE -1 * amount 
    END AS amount,
    type
FROM
    {{ source('internal', 'token_mint_burn') }}
