{% test numeric_value_at_least_zero(model, column_name) %}

WITH validation AS (
    SELECT 
        {{ column_name }} AS numeric_value
    FROM {{ model }}
),

test_validation AS (
    SELECT
        numeric_value
    FROM validation
    WHERE numeric_value < 0
)

SELECT
    *
FROM test_validation

{% endtest %}