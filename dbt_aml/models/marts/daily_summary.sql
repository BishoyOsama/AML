
{{
    config(
        materialized= 'incremental',
        unique_key= 'transaction_date'
    )
}}

SELECT
    transaction_timestamp::DATE AS transaction_date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_count,
    ROUND((100.0 * SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END)) / COUNT(*), 4) AS laundering_rate_percentage,
    COUNT(DISTINCT from_account_sk) AS active_sender_accounts,
    COUNT(DISTINCT to_account_sk) AS active_receiver_accounts
FROM {{ ref('fact_transactions') }}
WHERE transaction_timestamp::DATE = '{{ var("run_date" )}}'
GROUP BY transaction_timestamp::DATE