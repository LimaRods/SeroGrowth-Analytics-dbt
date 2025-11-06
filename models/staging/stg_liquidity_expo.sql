SELECT
    id,
    address AS user,
    market,
    CASE
        WHEN market = 'GhjqLUcaCrfH9s6bM5H9GvbWoDTYGsdXxVubP8J57cUr' THEN 'Exponent LP'
    END AS symbol,
    CASE
        WHEN market = 'GhjqLUcaCrfH9s6bM5H9GvbWoDTYGsdXxVubP8J57cUr' THEN amount_raw/POW(10,6)
    END AS amount,
    start_timestamp_ntz,
    end_timestamp_ntz

FROM
    {{ source("internal","exponent_liquidity_positions") }}