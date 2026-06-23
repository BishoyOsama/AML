{% test date_format(model, column_name) %}

WITH validation AS (
    SELECT
        {{ column_name }} AS date_column
    FROM {{ model }}
),

test_validation AS (
    SELECT
        date_column
    FROM validation
    WHERE TRY_TO_DATE(CAST(date_column AS VARCHAR), 'YYYY-MM-DD') IS NULL
)

SELECT
    *
FROM test_validation

{% endtest %}