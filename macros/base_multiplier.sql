-- macros/base_multiplier.sql
{% macro base_multiplier(symbol_col) %}

CASE
  WHEN {{ symbol_col }} = 'USX'        THEN 3
  WHEN {{ symbol_col }} = 'eUSX'       THEN 1
  WHEN {{ symbol_col }} = 'eUSX/USX'   THEN 3
  WHEN {{ symbol_col }} LIKE 'USX/%'   THEN 4
  ELSE 1
END

{% endmacro %}