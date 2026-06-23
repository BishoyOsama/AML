
SELECT
    from_bank AS from_bank_id,
    to_bank AS to_bank_id,
    payment_currency AS currency,
    COUNT(*) AS total_transactions,
    SUM(amount_paid) AS total_transferred
FROM {{ ref('fact_transactions') }}
GROUP BY from_bank, to_bank, payment_currency
