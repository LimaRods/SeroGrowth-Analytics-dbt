SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    {{ token_metadata('collateral_mint') }} AS symbol,
    collateral_sender_vault,
    amount,
    custodian,
    stable_depository,
    type
FROM
    {{ ref('stg_usx_vault') }}
