SELECT
pattern_group_id
FROM {{ ref('dim_patterns') }}
WHERE chain_length <= 0 AND pattern_group_id > 0