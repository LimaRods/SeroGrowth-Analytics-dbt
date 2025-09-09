{% macro base_multiplier(protocol_expr, product_expr) %}
-- Returns a SQL CASE expression; pass literals or columns, e.g.:
--   {{ base_multiplier("'Solstice'", "symbol") }}
--   {{ base_multiplier('protocol', 'product') }}
(
  CASE
    WHEN {{ protocol_expr }} = 'Solstice' THEN
      CASE
        WHEN {{ product_expr }} = 'USX'  THEN 3
        WHEN {{ product_expr }} = 'eUSX' THEN 1
        ELSE 1
      END

    WHEN {{ protocol_expr }} IN ('Orca','Raydium','Meteora') THEN
      CASE
        WHEN {{ product_expr }} = 'eUSX/USX' THEN 3
        WHEN {{ product_expr }} IN ('USX/USDC','USX/USDT') THEN 4
        -- Optional catch-all for any USX/* pool:
        WHEN LEFT({{ product_expr }}, 4) = 'USX/' THEN 4
        ELSE 1
      END

    ELSE 1
  END
)
{% endmacro %}