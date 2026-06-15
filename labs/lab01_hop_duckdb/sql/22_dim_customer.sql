-- sql/22_dim_customer.sql
INSERT INTO warehouse.dim_customer
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id)       AS customer_key,
    customer_id                                    AS customer_id_src,
    customer_name,
    COALESCE(email, 'unknown@unknown.com')          AS email,
    city,
    country,
    signup_date,
    segment,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM staging.customers;
