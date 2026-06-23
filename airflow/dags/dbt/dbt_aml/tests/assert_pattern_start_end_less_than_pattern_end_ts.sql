SELECT
pattern_group_id
FROM {{ ref('dim_patterns') }}
WHERE pattern_start_ts > pattern_end_ts 