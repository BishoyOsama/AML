
{{
    config(
        materialized= 'incremental',
        unique_key= 'transaction_sk',
        on_schema_change= 'sync_all_columns'
    )
}}

WITH transactions AS (
    SELECT 
        *
    FROM {{ ref('transactions') }}
    WHERE transaction_timestamp::DATE = '{{ var("run_date") }}'::DATE
),
patterns AS (
    SELECT
        pattern_group_id,
        transaction_sk,
        timestamp
    FROM {{ ref('patterns') }}
),
accounts AS (
    SELECT
        *
    FROM {{ ref('accounts') }}
)


SELECT
    t.transaction_sk AS transaction_sk,
    t.transaction_timestamp AS transaction_timestamp,
    t.from_account_sk AS from_account_sk,
    t.from_account AS from_account,
    t.from_bank AS from_bank,
    t.to_account_sk AS to_account_sk,
    t.to_account AS to_account,
    t.to_bank AS to_bank,
    ROUND(t.amount_received, 2) AS amount_received,
    t.receiving_currency AS receiving_currency,
    ROUND(t.amount_paid, 2) AS amount_paid,
    t.payment_currency AS payment_currency,
    t.payment_format AS payment_format,
    t.is_cross_currency AS is_cross_currency,
    t.is_cross_border AS is_cross_border,
    t.is_laundering AS is_laundering,
    COALESCE(p.pattern_group_id, -1) AS pattern_group_id,
    a.entity_id AS from_entity_id,
    a2.entity_id AS to_entity_id
FROM transactions t
LEFT JOIN patterns p
    ON t.transaction_timestamp = p.timestamp
    AND t.transaction_sk = p.transaction_sk
LEFT JOIN accounts a
    ON t.from_account_sk = a.bank_account_surrogate_key
LEFT JOIN accounts a2
    ON t.to_account_sk = a2.bank_account_surrogate_key

