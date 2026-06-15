SELECT
    transaction_sk
FROM {{ ref('fact_transactions') }}
WHERE (amount_paid != amount_received) AND (payment_currency = receiving_currency)