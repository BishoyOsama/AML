SELECT
    transaction_sk,
    amount_paid
FROM {{ ref('transactions') }}
WHERE amount_paid < 0
