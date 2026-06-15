
SELECT
    CAST(pattern_group_id AS int) AS pattern_group_id,
    pattern_type,
    pattern_metadata,
    MD5(
        from_account || '-' || to_account || '-' || timestamp
    )   AS transaction_sk,
    TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI') AS timestamp,
    {{ generate_sk_with_sep('from_account', 'CAST(from_bank AS INT)::VARCHAR') }} AS from_bank_account_sk,
    CAST(from_bank AS INT) AS from_bank,
    from_account,
    {{ generate_sk_with_sep('to_account', 'CAST(to_bank AS INT)::VARCHAR') }} AS to_bank_account_sk,
    CAST(to_bank AS INT) AS to_bank,
    to_account,
    CAST(amount_received AS FLOAT) AS amount_received,
    receiving_currency,
    CAST(amount_paid AS FLOAT) AS amount_paid,
    payment_currency,
    payment_format,
    CAST(is_laundering AS BOOLEAN) AS is_laundering
FROM {{ source('raw', 'patterns') }}