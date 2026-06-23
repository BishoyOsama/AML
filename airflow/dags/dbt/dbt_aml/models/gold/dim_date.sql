WITH minute_spine AS (
    SELECT
        DATEADD('minute', SEQ4(), '2022-08-30'::TIMESTAMP) AS date_time
    FROM TABLE(GENERATOR(ROWCOUNT => 1440 * 31)) 
)

SELECT
    date_time AS date_time_sk,
    CAST(date_time AS DATE) AS date,
    EXTRACT(HOUR FROM date_time) AS hour,
    EXTRACT(MINUTE FROM date_time) AS minute,
    DAYNAME(date_time) AS day_name,
    DAYOFWEEK(date_time) IN (1, 7) AS is_weekend,
    WEEKOFYEAR(date_time) AS week_of_year,
    MONTH(date_time) AS month,
    MONTHNAME(date_time) AS month_name,
    QUARTER(date_time) AS quarter,
    YEAR(date_time) AS year
FROM minute_spine