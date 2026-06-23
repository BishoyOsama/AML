
{{
    config(
        materialized= 'incremental',
        unique_key= ['bank_account_sk', 'transaction_date', 'currency']
    )
}}

WITH transactions AS (
    SELECT
        *
    FROM {{ ref('fact_transactions') }}
    WHERE transaction_timestamp::DATE = '{{ var("run_date") }}'::DATE
),
sent AS (
    SELECT
        from_account_sk AS bank_account_sk,
        transaction_timestamp::DATE AS transaction_date,
        payment_currency AS currency,
        SUM(amount_paid) AS total_amount_transferred
    FROM transactions
    GROUP BY from_account_sk, transaction_timestamp::DATE, payment_currency
),
received AS (
    SELECT
        to_account_sk AS bank_account_sk,
        transaction_timestamp::DATE AS transaction_date,
        receiving_currency AS currency,
        SUM(amount_received) AS total_amount_received
    FROM transactions
    GROUP BY to_account_sk, transaction_timestamp::DATE, receiving_currency
),
combined AS (
    SELECT
        COALESCE(s.bank_account_sk, r.bank_account_sk) AS bank_account_sk,
        COALESCE(s.transaction_date, r.transaction_date) AS transaction_date,
        COALESCE(s.currency, r.currency)  AS currency,
        COALESCE(s.total_amount_transferred, 0) AS amount_transferred,
        COALESCE(r.total_amount_received, 0)  AS amount_received,
        COALESCE(r.total_amount_received, 0)   - COALESCE(s.total_amount_transferred, 0)  AS net_flow
    FROM sent s
    FULL OUTER JOIN received r
        ON s.bank_account_sk = r.bank_account_sk
        AND s.transaction_date = r.transaction_date
        AND s.currency = r.currency
)

SELECT
    bank_account_sk,
    transaction_date,
    currency,
    ROUND(amount_transferred, 2) AS amount_transferred,
    ROUND(amount_received, 2) AS amount_received,
    net_flow
FROM combined
