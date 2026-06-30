SELECT
    transaction_sk,
    amount_received
FROM {{ ref('transactions') }}
WHERE amount_received < 0
