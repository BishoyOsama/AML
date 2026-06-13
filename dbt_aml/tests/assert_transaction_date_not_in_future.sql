SELECT
    transaction_date
FROM {{ ref('transactions') }}
WHERE transaction_date > CURRENT_DATE()