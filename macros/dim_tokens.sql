
--  Token dictionary: edit this when replacing the tokens
{% macro token_meta_map() %}
  {%- set TOKENS = {
    '5dXXpWyZCCPhBHxmp79Du81t7t9oh7HacUW864ARFyft': {'symbol': 'USDT',  'decimals': 6},
    '8iBux2LRja1PhVZph8Rw4Hi45pgkaufNEiaZma5nTD5g': {'symbol': 'USDC',  'decimals': 6},
    '7QC4zjrKA6XygpXPQCKSS9BmAsEFDJR6awiHSdgLcDvS': {'symbol': 'USX',   'decimals': 6},
    'Abjx9zzdatgA18ezxRhveJVU65T7NbKqiByremdpQVR1': {'symbol': 'USX',   'decimals': 6},
    '6FrrzDk5mQARGc1TDYoyVnSyRdds1t4PbtohCD6p3tgG': {'symbol': 'USX',   'decimals': 6},
    'Gkt9h4QWpPBDtbaF5HvYKCc87H5WCRTUtMf77HdTGHB': {'symbol': 'eUSX',   'decimals': 6},
    '2RSo4tLSFHrco9bwboomq9CGEvnPEVoBSkqZSh87xq1j': {'symbol': 'eUSX',   'decimals': 6},
    '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU': {'symbol': 'eUSX', 'decimals': 6},
    'YG6SXWt43x6KHGELkjRug8WxL64hsGVzQ6V22zsbJJ4': {'symbol': 'Token2', 'decimals': 6}



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
    ELSE {{ "'UNKNOWN'" if field == 'symbol' else 'NULL' }}
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