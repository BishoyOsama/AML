
{{
    config(
        materialized= 'incremental',
        unique_key= ['transaction_date', 'payment_currency']
    )
}}


SELECT
    transaction_timestamp::DATE  AS transaction_date,
    payment_currency,
    COUNT(*)        AS total_transactions,
    SUM(amount_paid)  AS total_transferred,
    SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_count,
    ROUND(SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) / COUNT(*), 6) AS laundering_rate
FROM {{ ref('fact_transactions') }}
WHERE transaction_timestamp::DATE = '{{ var("run_date") }}'
GROUP BY transaction_timestamp::DATE, payment_currency