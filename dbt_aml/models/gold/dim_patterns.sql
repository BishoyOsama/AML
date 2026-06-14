

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
ORDER BY pattern_group_id ASC
