
SELECT
    DISTINCT bank_id, bank_name
FROM {{ ref('accounts') }}