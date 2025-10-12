SELECT
    SUM(awarded_points) AS total_points

FROM
    {{ref('int_quest_completion')}}