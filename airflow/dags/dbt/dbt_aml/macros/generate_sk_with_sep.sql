
{% macro generate_sk_with_sep(column_one, column_two) %}

    MD5(
        CONCAT_WS(
            '-', CAST({{ column_one }} AS VARCHAR) , CAST({{ column_two }} AS VARCHAR)
            )
        )

{% endmacro %}
