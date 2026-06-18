
{{
    config(
        materialized= 'incremental',
        unique_key= ['bank_account_sk', 'transaction_date']
    )
}}

WITH transactions AS(
    SELECT
        *
    FROM {{ ref('fact_transactions') }}
    WHERE transaction_timestamp::DATE = '{{ var("run_date") }}'::DATE
),
sent AS (
    SELECT
        from_account_sk AS bank_account_sk, 
        transaction_timestamp::DATE AS transaction_date,
        COUNT(*) AS transactions_sent,
        COUNT(DISTINCT to_account_sk)  AS unique_counterparties_sent_to,
        COUNT(DISTINCT to_bank)  AS unique_banks_sent_to,
        SUM(CASE WHEN is_cross_currency THEN 1 ELSE 0 END)  AS cross_currency_sent_count,
        SUM(CASE WHEN is_cross_border THEN 1 ELSE 0 END) AS cross_border_sent_count,
        SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_sent_count,
        COUNT(DISTINCT payment_format)  AS distinct_payment_formats,
        COUNT(DISTINCT CASE WHEN pattern_group_id = -1 THEN NULL ELSE pattern_group_id END) AS distinct_patterns_count 
    FROM transactions
    GROUP BY from_account_sk, transaction_timestamp::DATE
),
received AS (
    SELECT
        to_account_sk   AS bank_account_sk,
        transaction_timestamp::DATE AS transaction_date,
        COUNT(*) AS transactions_received,
        COUNT(DISTINCT from_account_sk) AS unique_counterparties_received_from,
        COUNT(DISTINCT from_bank) AS unique_banks_received_from,
        SUM(CASE WHEN is_cross_currency THEN 1 ELSE 0 END) AS cross_currency_received_count,
        SUM(CASE WHEN is_cross_border THEN 1 ELSE 0 END) AS cross_border_received_count,
        COUNT(DISTINCT payment_format) AS distinct_payment_formats,
        SUM(CASE WHEN is_laundering THEN 1 ELSE 0 END) AS laundering_received_count,
        COUNT(DISTINCT CASE WHEN pattern_group_id = -1 THEN NULL ELSE pattern_group_id END) AS distinct_patterns_count
    FROM transactions
    GROUP BY to_account_sk, transaction_timestamp::DATE
),

combined AS (
    SELECT
        COALESCE(s.bank_account_sk, r.bank_account_sk) AS bank_account_sk,
        COALESCE(s.transaction_date, r.transaction_date) AS transaction_date,
        COALESCE(s.transactions_sent, 0) AS transactions_sent,
        COALESCE(r.transactions_received, 0) AS transactions_received,
        COALESCE(s.unique_counterparties_sent_to, 0) AS unique_counterparties_sent_to,
        COALESCE(r.unique_counterparties_received_from, 0) AS unique_counterparties_received_from,
        COALESCE(s.unique_banks_sent_to, 0) AS unique_banks_sent_to,
        COALESCE(r.unique_banks_received_from, 0) AS unique_banks_received_from,
        COALESCE(s.cross_currency_sent_count, 0) + COALESCE(r.cross_currency_received_count, 0) AS cross_currency_txn_count,
        COALESCE(s.cross_border_sent_count, 0) + COALESCE(r.cross_border_received_count, 0) AS cross_border_txn_count,
        COALESCE(s.laundering_sent_count, 0) + COALESCE(r.laundering_received_count, 0) AS laundering_txn_count,
        COALESCE(s.distinct_payment_formats, r.distinct_payment_formats) AS distinct_payment_formats,
        COALESCE(s.distinct_patterns_count, r.distinct_patterns_count) AS distinct_patterns_count
    FROM sent s
    FULL OUTER JOIN received r
        ON s.bank_account_sk = r.bank_account_sk
        AND s.transaction_date = r.transaction_date
)


SELECT
    bank_account_sk,
    transaction_date,
    transactions_sent,
    transactions_received,
    unique_counterparties_sent_to,
    unique_counterparties_received_from,
    unique_banks_sent_to,
    unique_banks_received_from,
    cross_currency_txn_count,
    cross_border_txn_count,
    laundering_txn_count,
    laundering_txn_count > 0    AS is_flagged_account_day,
    distinct_payment_formats,
    distinct_patterns_count
FROM combined