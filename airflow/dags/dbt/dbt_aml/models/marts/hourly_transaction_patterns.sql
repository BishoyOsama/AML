
{{
    config(
        materialized= 'incremental',
        unique_key= ['transaction_date', 'hour', 'currency', 'payment_format']
    )
}}

WITH transactions AS (
    SELECT
        *
    FROM {{ ref('fact_transactions') }}
    WHERE transaction_timestamp::DATE = '{{ var("run_date") }}'
)

SELECT
    transaction_timestamp::DATE AS transaction_date,
    EXTRACT(HOUR FROM transaction_timestamp) AS hour,
    payment_currency AS currency,
    payment_format,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_count,
    SUM(amount_paid)  AS total_transferred
FROM transactions
GROUP BY transaction_timestamp::DATE, EXTRACT(HOUR FROM transaction_timestamp), payment_currency, payment_format
ORDER BY transaction_date, hour