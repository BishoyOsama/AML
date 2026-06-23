WITH day_spine AS (
    SELECT
        DATEADD('day', SEQ4(), '2022-08-30'::DATE) AS date
    FROM TABLE(GENERATOR(ROWCOUNT => 30)) 
)

SELECT
    date AS date_sk,
    DAY(date) AS day_num,
    DAYNAME(date) AS day_name,
    DAYOFWEEK(date) IN (1, 7) AS is_weekend,
    WEEKOFYEAR(date) AS week_of_year,
    MONTH(date) AS month,
    MONTHNAME(date) AS month_name,
    QUARTER(date) AS quarter,
    YEAR(date) AS year
FROM day_spine