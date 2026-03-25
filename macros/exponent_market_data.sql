{% macro exponent_market_metadata() %}
(
    SELECT *
    FROM (
        VALUES
            (
                '31XQjgfV5PiF2yXEbyctpq7gZ1TALkC9JvygjiR8xJrB', -- market_id
                'USX-09FEB26',                                -- market_name
                'USX',                                        -- underlying_symbol
                '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG', -- underlying_token_address
                'HQmMS5W34VcMtR85akhZgvypy7iqVWRXi282vwdf9eTX', -- yt_mint_address
                '7vWj1UriSscGmz5wadAC8EkA8ndoU3M7WUifqxTC3Ysf', -- pt_mint_address
                '6K6bDA3f2heMYZQzbu3GDzx73zEXCeWZ58msfc1kDA6n'  -- lp_mint_address
            ),
            (
                'BxbiZpzj32nrVGecFy8VQ1HohaW7ryhas1k9aiETDWdm',
                'USX-01JUN26',
                'USX',
                '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG',
                'Au8g11nXqXrUAmL14GM3gQnrnJnr4dcpgc5DNAnu9F9s',
                '3kctCXgt6pP3uZcek8SqNK2KZdQ6cqtj9hc3U46jhgBk',
                'BR2JKV9gPoJfX8A8DkFmo2yNQKCeGipg33oYaZ4EmjbW'
            ),
            (
                'GhjqLUcaCrfH9s6bM5H9GvbWoDTYGsdXxVubP8J57cUr',
                'eUSX-11MAR26',
                'eUSX',
                '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC',
                'DDoYyEUcdkHV5a4NCPXDRL9f93NgPbqK9ZANAGL627wF',
                '6oiDcfve7ybKUC8ysZmncC9iSuxQG2vrRkh3dgV7EKR4',
                'Gz6LTebmfQqjbQD4C5NzqFN6PVWRd9pG3BJ4p4xHeDxF'
            ),
            (
                'rBbzpGk3PTX8mvQg95VWJ24EDgvxyDJYrEo9jtauvjP',
                'eUSX-01JUN26',
                'eUSX',
                '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC',
                'GEYwnvNzqFXrLnNq4riXbn2ASnwU3cF8RXW6wXKHM4sw',
                'BNR2FsHo8JrYGWx2V8yxG5GBWiG3uU8voi2eMGBHFwEj',
                '4GT6g1iKx2TyYCkwt1tERkReQjSUuVE7uh14M5W8v2nn'
            )
    ) AS t (
        market_id,
        market_name,
        underlying_symbol,
        underlying_token_address,
        yt_mint_address,
        pt_mint_address,
        lp_mint_address
    )
)
{% endmacro %}