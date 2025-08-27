SELECT
    id,
    timestamp_ntz,
    signature,
    requestor,
    collateral_mint,
    CASE
        WHEN  type = 'CONFIRM_MINT' THEN collateral_amount
        ELSE -1 * collateral_amount 
    END AS amount,
    type
FROM
    {{ source('internal', 'usx_mint_redeem') }}
