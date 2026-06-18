WITH laundering_transactions AS (
    SELECT
        pattern_group_id,
        payment_format,
        payment_currency AS currency,
        COUNT(*) AS total_transactions
    FROM {{ ref('fact_transactions') }}
    WHERE is_laundering = TRUE
    GROUP BY pattern_group_id, payment_format, payment_currency
),

patterns AS (
    SELECT
        pattern_group_id,
        pattern_type,
        pattern_metadata,
        chain_length,
        pattern_duration_days
    FROM {{ ref('dim_patterns') }}
)

SELECT
    lf.pattern_group_id,
    COALESCE(p.pattern_type, 'Unclassified')   AS pattern_type,
    p.pattern_metadata,
    lf.payment_format,
    lf.currency,
    lf.total_transactions,
    p.chain_length,
    p.pattern_duration_days                  AS duration_days
FROM laundering_transactions lf
LEFT JOIN patterns p
    ON lf.pattern_group_id = p.pattern_group_id