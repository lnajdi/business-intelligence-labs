-- sql/25_dim_geo.sql
INSERT INTO warehouse.dim_geo
SELECT
    ROW_NUMBER() OVER (ORDER BY city)              AS geo_key,
    city,
    country
FROM (
    SELECT DISTINCT city, country FROM staging.customers
    UNION
    SELECT DISTINCT city, 'MA' AS country FROM staging.orders WHERE city IS NOT NULL
) t
WHERE city IS NOT NULL AND city <> 'Unknown';
