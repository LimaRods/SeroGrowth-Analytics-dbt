SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    collateral_mint,
    collateral_sender_vault,
    CASE
        WHEN type = 'TRANSFER_IN_COLLATERAL' THEN amount
        ELSE -1 * amount 
    END AS amount,
    custodian,
    stable_depository,
    type
FROM
    {{ source('internal', 'usx_vault') }}
