
SELECT
    DISTINCT bank_account_surrogate_key, account_number, bank_id
FROM {{ ref('accounts') }}