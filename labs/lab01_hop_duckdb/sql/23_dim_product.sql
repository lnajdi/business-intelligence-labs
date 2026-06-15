-- sql/23_dim_product.sql
INSERT INTO warehouse.dim_product
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id)        AS product_key,
    product_id                                     AS product_id_src,
    product_name,
    category_id,
    category_name,
    department,
    unit_price,
    cost_price,
    active_flag,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM staging.products;
