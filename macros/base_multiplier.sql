{% macro base_multiplier(protocol, product) %}
  {# Keep case; just trim & unify "-" to "/" #}
  {% set proto = (protocol ~ '') | trim %}
  {% set prod  = (product  ~ '') | trim %}
  {% set prod_norm = prod | replace('-', '/') | trim %}

  {% set MAP = {
    'Solstice': {
      'USX': 3,
      'eUSX': 1
    },
    'Orca': {
      'USX/USDC': 4,
      'USX/USDT': 4,
      'eUSX/USX': 3
    },
    'Raydium': {
      'USX/USDC': 4,
      'USX/USDT': 4,
      'eUSX/USX': 3
    },
    'Meteora': {
      'USX/USDC': 4,
      'USX/USDT': 4,
      'eUSX/USX': 3
    }
  } %}

  {# 1) Exact match #}
  {% if MAP.get(proto) and MAP[proto].get(prod_norm) %}
    {{ return(MAP[proto][prod_norm]) }}
  {% endif %}

  {# 2) Minimal fallbacks matching your rules #}
  {% if proto in ['Orca','Raydium','Meteora'] %}
    {% if prod_norm == 'eUSX/USX' %}
      {{ return(3) }}
    {% elif prod_norm.startswith('USX/') %}
      {{ return(4) }}
    {% endif %}
  {% elif proto == 'Solstice' %}
    {% if prod_norm == 'USX' %}
      {{ return(3) }}
    {% elif prod_norm == 'eUSX' %}
      {{ return(1) }}
    {% endif %}
  {% endif %}

  {{ return(1) }}
{% endmacro %}