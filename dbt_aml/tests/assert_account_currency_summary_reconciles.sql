
WITH reconciles AS (
    SELECT 
        currency, ROUND(SUM(amount_transferred), 2) AS total
    FROM {{ ref('account_currency_summary') }}
    GROUP BY currency

    EXCEPT

    SELECT
        payment_currency AS currency, ROUND(SUM(amount_paid), 2) AS total
    FROM {{ ref('fact_transactions') }}
    GROUP BY payment_currency
)

SELECT
    currency,
    COUNT(*)
FROM reconciles
GROUP BY currency
HAVING COUNT(*) > 0