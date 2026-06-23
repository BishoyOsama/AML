{% test hour_range(model, column_name) %}

WITH validation AS (
    SELECT 
        {{ column_name }} AS hour
    FROM {{ model }}
),
test_validation AS (
    SELECT 
        hour
    FROM validation
    WHERE hour NOT BETWEEN 0 AND 23
)

SELECT
    *
FROM test_validation

{% endtest %}