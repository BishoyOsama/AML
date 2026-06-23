

SELECT
    DISTINCT entity_id, entity_name
FROM {{ ref('accounts') }}