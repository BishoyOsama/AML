{% test minute_range(model, column_name) %}

WITH validation AS (
    SELECT 
        {{ column_name }} AS minute
    FROM {{ model }}
),
test_validation AS (
    SELECT 
        minute
    FROM validation
    WHERE minute NOT BETWEEN 0 AND 59
)

SELECT
    *
FROM test_validation

{% endtest %}