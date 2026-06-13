SELECT {{ generate_sk_with_sep('"Account Number"', '"Bank ID"') }} AS bank_account_surrogate_key,
    "Account Number" AS account_number,
    "Bank ID" AS bank_id,
    "Bank Name" AS bank_name,
    "Entity ID" AS entity_id,
    "Entity Name" AS entity_name
FROM {{ source('raw', 'accounts') }} 
QUALIFY ROW_NUMBER() OVER(PARTITION BY "Account Number", "Bank ID" ORDER BY "Account Number") = 1