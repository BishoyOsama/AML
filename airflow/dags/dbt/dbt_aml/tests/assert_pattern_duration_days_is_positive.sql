SELECT
pattern_group_id
FROM {{ ref('dim_patterns') }}
WHERE pattern_duration_days < 0 AND pattern_group_id > 0