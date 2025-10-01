SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    collateral_sender_vault,
    collateral_mint AS token_mint_address,
    {{ token_symbol('collateral_mint') }} AS symbol,
    {{ token_amount_adj('amount','collateral_mint') }} AS amount,
    custodian,
    stable_depository,
    type
FROM
    {{ source('internal', 'usx_vault') }}

