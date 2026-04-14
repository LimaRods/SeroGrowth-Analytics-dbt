-- models/utils/dim_seasons.sql

{{ config(materialized='table') }}

SELECT 'Season 1' AS season, CAST('1900-01-01' AS DATE) AS start_date, CAST('2026-04-12' AS DATE) AS end_date
UNION ALL
SELECT 'Season 2' AS season, CAST('2026-04-13' AS DATE) AS start_date, CAST('9999-12-31' AS DATE) AS end_date