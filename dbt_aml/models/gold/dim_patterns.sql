

WITH original_patterns AS (
    SELECT
    pattern_group_id,
    pattern_type,
    pattern_metadata,
    COUNT(pattern_group_id) AS chain_length,
    MIN(timestamp) AS pattern_start_ts,
    MAX(timestamp) AS pattern_end_ts,
    DATEDIFF('day', MIN(timestamp), MAX(timestamp)) AS pattern_duration_days
    FROM {{ ref('patterns') }}
    GROUP BY pattern_group_id, pattern_type, pattern_metadata
),
unclassified_pattern AS (
    SELECT
        -1 AS pattern_group_id,
        'Unclassified' AS pattern_type,
        null AS pattern_metadata,
        -1 AS chain_length,
        null AS pattern_start_ts,
        null AS pattern_end_ts,
        -1 AS pattern_duration_days
)

SELECT 
    *
FROM original_patterns
UNION
SELECT
    *
FROM unclassified_pattern
ORDER BY pattern_group_id ASC
