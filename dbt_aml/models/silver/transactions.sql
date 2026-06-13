{{
    config(
        materialized='incremental',
        unique_key='transaction_sk',
        on_schema_change='sync_all_columns'
    )
}}


SELECT
    MD5(
        from_account || '-' || to_account || '-' || timestamp
    )   AS transaction_sk,
    TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI')::DATE AS transaction_date,
    EXTRACT(HOUR FROM TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI')) AS transaction_hour,
    EXTRACT(MINUTE FROM TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI')) AS transaction_minute,
    DAYNAME(TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI')) AS transaction_day,
    {{ generate_sk_with_sep('from_account', 'from_bank') }} AS from_account_sk,
    from_bank,
    from_account,
    {{ generate_sk_with_sep('to_account', 'to_bank') }} AS to_account_sk,
    to_bank,
    to_account,
    CAST(amount_received AS FLOAT) AS amount_received,
    receiving_currency,
    CAST(amount_paid AS FLOAT) AS amount_paid,
    payment_currency,
    payment_format,
    payment_currency != receiving_currency   AS is_cross_currency,
    from_bank != to_bank    AS is_cross_border,
    CAST(is_laundering AS BOOLEAN) AS is_laundering
FROM {{ source('raw', 'transactions') }}
WHERE TO_TIMESTAMP(timestamp, 'YYYY/MM/DD HH24:MI')::DATE = '{{ var("run_date") }}'::DATE
QUALIFY ROW_NUMBER() OVER(PARTITION BY from_account, to_account, timestamp ORDER BY from_account) = 1
