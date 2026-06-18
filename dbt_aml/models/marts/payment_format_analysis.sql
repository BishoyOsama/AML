

SELECT
    payment_format,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_count,
    ROUND(SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) / COUNT(*), 6) AS laundering_rate
FROM {{ ref('fact_transactions') }}
GROUP BY payment_format