SELECT
    id,
    signature,
    timestamp_ntz,
    harvester,
    asset_mint AS token_mint_address,
    {{ token_symbol('asset_mint') }} AS symbol,
    {{ token_amount_adj('asset_amount','asset_mint') }} AS amount,
    type,

FROM
     {{ source("internal","usx_yield_transfer") }}
 WHERE
    timestamp_ntz > TO_TIMESTAMP('2025-09-29')