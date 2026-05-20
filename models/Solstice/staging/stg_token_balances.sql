SELECT
    id,
    address AS user,
    token AS token_mint_address,
    {{ token_symbol('token') }} AS symbol,
    {{ token_amount_adj('amount_raw','token') }} AS amount,
    start_timestamp_ntz AS start_ts,
    end_timestamp_ntz AS end_ts

FROM
    {{ source('internal','token_balances')}}
WHERE  token IN ('6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG', -- USX
                '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC', -- eUSX
                'DDoYyEUcdkHV5a4NCPXDRL9f93NgPbqK9ZANAGL627wF', -- YT-eUSX-11MAR26
                --'Gz6LTebmfQqjbQD4C5NzqFN6PVWRd9pG3BJ4p4xHeDxF',
                --'6K6bDA3f2heMYZQzbu3GDzx73zEXCeWZ58msfc1kDA6n',
                'HQmMS5W34VcMtR85akhZgvypy7iqVWRXi282vwdf9eTX', -- YT-USX-09FEB26
                'Au8g11nXqXrUAmL14GM3gQnrnJnr4dcpgc5DNAnu9F9s', -- YT-USX-01JUN26
                'GEYwnvNzqFXrLnNq4riXbn2ASnwU3cF8RXW6wXKHM4sw' -- YT-eUSX-01JUN26

                ) -- USX, eUSX, YT AND ELP