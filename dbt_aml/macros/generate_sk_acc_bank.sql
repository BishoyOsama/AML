
{% macro generate_sk_acc_bank(account_id, bank_id) %}

    MD5(
        CONCAT_WS(
            '-', CAST({{ account_id }} AS VARCHAR) , CAST({{ bank_id }} AS VARCHAR)
            )
        )

{% endmacro %}
