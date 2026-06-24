-- sql/23_dim_product.sql
-- product_key n'est PAS frappée ici : DEFAULT nextval('warehouse.seq_dim_product').
-- category_name + department sont dénormalisés dans dim_product (étoile, pas flocon).
-- LEFT JOIN : on garde le produit même sans catégorie (category_name/department NULL).
INSERT INTO warehouse.dim_product
    (product_id_src, product_name, category_id, category_name,
     department, unit_price, cost_price, active_flag, loaded_at)
SELECT
    p.product_id                                   AS product_id_src,
    p.product_name,
    p.category_id,
    c.category_name,
    c.department,
    p.unit_price,
    p.cost_price,
    p.active_flag,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM staging.products p
LEFT JOIN staging.categories c ON p.category_id = c.category_id
WHERE p.product_id IS NOT NULL;
