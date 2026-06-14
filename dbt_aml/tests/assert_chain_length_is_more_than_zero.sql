SELECT
pattern_group_id
FROM {{ ref('dim_patterns') }}
WHERE chain_length <= 0