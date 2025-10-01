SELECT
    id,
    timestamp_ntz,
    signature,
    user,
    asset_mint AS token_mint_address,
    {{ token_symbol('asset_mint') }} AS symbol,
    {{ token_amount_adj('amount','asset_mint') }} AS amount, 
    type,
FROM
    {{ source("internal","yield_vault") }}
WHERE
    timestamp_ntz > TO_TIMESTAMP('2025-09-29')

