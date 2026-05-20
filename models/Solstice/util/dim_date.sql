
{{ config(materialized='table') }}

{{ dbt_utils.date_spine(
    datepart = "day",
    start_date = "DATE('2025-01-01')",
    end_date   = "DATEADD(day,1,CURRENT_DATE())"
) }}