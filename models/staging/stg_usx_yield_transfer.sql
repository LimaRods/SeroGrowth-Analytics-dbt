SELECT
    id,
    signature,
    timestamp_ntz,
    harvester,
    asset_mint,
    asset_amount AS amount

FROM
     {{ source("internal","usx_yield_transfer") }}