-- macros/loyalty_tier.sql

{% macro loyalty_multiplier(days_expr) %}
  {#
    Compounds using the *current tier's daily rate* across the full streak:
      - Day 1–15  → HODLer        → 1.012^days
      - Day 15–30 → Maxi          → 1.014^days
      - Day 30–60 → Diamond Hands → 1.016^days
      - Day 60–90+→ Veteran       → 1.018^days
  #}
  POWER(
    CASE
      WHEN {{ days_expr }} >= 60 THEN 1.018   -- Veteran
      WHEN {{ days_expr }} >= 30 THEN 1.016   -- Diamond Hands
      WHEN {{ days_expr }} >= 15 THEN 1.014   -- Maxi
      WHEN {{ days_expr }} >= 1  THEN 1.012   -- HODLer
      ELSE 1.0
    END,
    GREATEST({{ days_expr }}, 0)
  )
{% endmacro %}

{% macro loyalty_tier_label(days_expr) %}
  CASE
    WHEN {{ days_expr }} >= 60 THEN 'Veteran'
    WHEN {{ days_expr }} >= 30 THEN 'Diamond Hands'
    WHEN {{ days_expr }} >= 15 THEN 'Maxi'
    WHEN {{ days_expr }} >= 1  THEN 'HODLer'
    ELSE 'None'
  END
{% endmacro %}