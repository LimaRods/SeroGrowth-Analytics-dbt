
--  Token dictionary: edit this when replacing the tokens
{% macro token_meta_map() %}
  {%- set TOKENS = {
    'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB': {'symbol': 'USDT',  'decimals': 6},
    'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v': {'symbol': 'USDC',  'decimals': 6},
    '2u1tszSeqZ3qBWF3uNGPFc8TzMk2tdiwknnRMWGWjGWH': {'symbol': 'USDG',  'decimals': 6},
    '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG': {'symbol': 'USX',   'decimals': 6},
    '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC': {'symbol': 'eUSX',   'decimals': 6},
    'Gz6LTebmfQqjbQD4C5NzqFN6PVWRd9pG3BJ4p4xHeDxF': {'symbol': 'ELP-eUSX-11MAR26','decimals': 6},
    'DDoYyEUcdkHV5a4NCPXDRL9f93NgPbqK9ZANAGL627wF': {'symbol': 'YT-eUSX-11MAR26', 'decimals': 6},
    '6oiDcfve7ybKUC8ysZmncC9iSuxQG2vrRkh3dgV7EKR4': {'symbol': 'PT-eUSX-11MAR26', 'decimals': 6},
    '6K6bDA3f2heMYZQzbu3GDzx73zEXCeWZ58msfc1kDA6n': {'symbol': 'ELP-USX-09FEB26', 'decimals': 6},
    'HQmMS5W34VcMtR85akhZgvypy7iqVWRXi282vwdf9eTX': {'symbol': 'YT-USX-09FEB26', 'decimals': 6},
    '7vWj1UriSscGmz5wadAC8EkA8ndoU3M7WUifqxTC3Ysf': {'symbol': 'PT-USX-09FEB26', 'decimals': 6},
    'BR2JKV9gPoJfX8A8DkFmo2yNQKCeGipg33oYaZ4EmjbW': {'symbol': 'ELP-USX-01JUN26', 'decimals': 6},
    'Au8g11nXqXrUAmL14GM3gQnrnJnr4dcpgc5DNAnu9F9s': {'symbol': 'YT-USX-01JUN26', 'decimals': 6},
    '3kctCXgt6pP3uZcek8SqNK2KZdQ6cqtj9hc3U46jhgBk': {'symbol': 'PT-USX-01JUN26', 'decimals': 6},
    '4GT6g1iKx2TyYCkwt1tERkReQjSUuVE7uh14M5W8v2nn': {'symbol': 'ELP-eUSX-01JUN26', 'decimals': 6},
    'GEYwnvNzqFXrLnNq4riXbn2ASnwU3cF8RXW6wXKHM4sw': {'symbol': 'YT-eUSX-01JUN26', 'decimals': 6},
    'BNR2FsHo8JrYGWx2V8yxG5GBWiG3uU8voi2eMGBHFwEj': {'symbol': 'PT-eUSX-01JUN26', 'decimals': 6}




  } -%}
  {{ return(TOKENS) }}
{% endmacro %}

-- CASE emitter
{% macro token_metadata(mint_expr, field='symbol') %}
  {% set tokens = token_meta_map() %}
  CASE
  {% for addr, meta in tokens.items() %}
    WHEN LOWER({{ mint_expr }}) = '{{ addr|lower }}' THEN
      {% if field == 'symbol' %}
        '{{ meta['symbol'] }}'
      {% elif field == 'decimals' %}
        {{ meta['decimals'] if meta['decimals'] is not none else 'NULL' }}
      {% else %}
        NULL
      {% endif %}
  {% endfor %}
    ELSE {{ 'NULL' if field == 'symbol' else 'NULL' }}
  END
{% endmacro %}

-- Token metadata emitter
{% macro token_symbol(mint_expr) %}
  {{ token_metadata(mint_expr, 'symbol') }}
{% endmacro %}

{% macro token_decimals(mint_expr) %}
  {{ token_metadata(mint_expr, 'decimals') }}
{% endmacro %}

-- Token amount adjustment
{% macro token_scale(mint_expr, default_decimals=6) %}
  POWER(
    10,
    COALESCE({{ token_decimals(mint_expr) }}, {{ default_decimals }})
  )
{% endmacro %}

{% macro token_amount_adj(amount_expr, mint_expr, precision=38, scale=18, default_decimals=6) %}
  CAST(
    ( {{ amount_expr }} / {{ token_scale(mint_expr, default_decimals) }} )
    AS NUMBER({{ precision }}, {{ scale }})
  )
{% endmacro %}