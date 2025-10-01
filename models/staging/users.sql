SELECT
    *
FROM
    {{ source("internal","users")}}
WHERE
    join_date >= TO_TIMESTAMP_NTZ('2025-09-30')