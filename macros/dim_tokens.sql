
--  Token dictionary: edit this when replacing the tokens
{% macro token_meta_map() %}
  {%- set TOKENS = {
    'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB': {'symbol': 'USDT',  'decimals': 6},
    'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v': {'symbol': 'USDC',  'decimals': 6},
    '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG': {'symbol': 'USX',   'decimals': 6},
    '3ThdFZQKM6kRyVGLG48kaPg5TRMhYMKY1iCRa9xop1WC': {'symbol': 'eUSX',   'decimals': 6},
    'Gz6LTebmfQqjbQD4C5NzqFN6PVWRd9pG3BJ4p4xHeDxF': {'symbol': ' Expo LP eUSX','decimals': 6},
    'DDoYyEUcdkHV5a4NCPXDRL9f93NgPbqK9ZANAGL627wF': {'symbol': 'YT-eUSX', 'decimals': 7}



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