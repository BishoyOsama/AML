
{{
    config(
        materialized= 'incremental',
        unique_key= ['transaction_date', 'hour']
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
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_count,
    ROUND(SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) / COUNT(*), 6) AS laundering_rate,
    COUNT(DISTINCT from_account_sk) AS active_sender_accounts,
    COUNT(DISTINCT to_account_sk) AS active_receiver_accounts
FROM transactions
GROUP BY transaction_timestamp::DATE, EXTRACT(HOUR FROM transaction_timestamp)
ORDER BY transaction_date, hour