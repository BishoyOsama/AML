WITH laundering_transactions AS (
    SELECT
        pattern_group_id,
        payment_format,
        payment_currency AS currency,
        COUNT(*) AS total_transactions,
        COUNT(pattern_group_id) AS chain_length,
        DATEDIFF('day', MIN(transaction_timestamp), MAX(transaction_timestamp)) AS pattern_duration_days
    FROM {{ ref('fact_transactions') }}
    WHERE is_laundering = TRUE
    GROUP BY pattern_group_id, payment_format, payment_currency
),

patterns AS (
    SELECT
        pattern_group_id,
        pattern_type,
        pattern_metadata
    FROM {{ ref('dim_patterns') }}
)

SELECT
    lf.pattern_group_id,
    COALESCE(p.pattern_type, 'Unclassified')   AS pattern_type,
    p.pattern_metadata,
    lf.payment_format,
    lf.currency,
    lf.total_transactions,
    lf.chain_length,
    lf.pattern_duration_days                  AS duration_days
FROM laundering_transactions lf
LEFT JOIN patterns p
    ON lf.pattern_group_id = p.pattern_group_id