
SELECT
    CAST(pattern_group_id AS int) AS pattern_group_id,
    pattern_type,
    pattern_metadata,
    TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI') AS timestamp,
    {{ generate_sk_acc_bank('from_account', 'from_bank') }} AS from_bank_account_sk,
    from_bank,
    from_account,
    {{ generate_sk_acc_bank('to_account', 'to_bank') }} AS to_bank_account_sk,
    to_bank,
    to_account,
    CAST(amount_received AS FLOAT) AS amount_received,
    receiving_currency,
    CAST(amount_paid AS FLOAT) AS amount_paid,
    payment_currency,
    payment_format,
    CAST(is_laundering AS BOOLEAN) AS is_laundering
FROM {{ source('raw', 'patterns') }}