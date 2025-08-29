SELECT
    id,
    signature,
    timestamp_ntz,
    harvester,
    {{ token_metadata('asset_mint') }} AS symbol,
    amount

FROM
    {{ ref('stg_usx_yield_transfer') }}