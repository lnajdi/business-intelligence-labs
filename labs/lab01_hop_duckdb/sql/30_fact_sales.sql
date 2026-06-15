-- sql/30_fact_sales.sql
-- Grain: one row per order line item

TRUNCATE warehouse.fact_sales;

INSERT INTO warehouse.fact_sales
SELECT
    oi.order_item_id                                                       AS sales_key,
    dd.date_key,
    dc.customer_key,
    dp.product_key,
    dch.channel_key,
    o.order_id,
    oi.quantity,
    oi.unit_price                                                          AS sale_unit_price,
    dp.cost_price                                                          AS cost_unit_price,
    oi.discount_amount,
    (oi.quantity * oi.unit_price)                                          AS gross_amount,
    (oi.quantity * oi.unit_price - oi.discount_amount)                     AS net_amount,
    (oi.quantity * dp.cost_price)                                          AS cost_amount,
    (oi.quantity * oi.unit_price - oi.discount_amount
        - oi.quantity * dp.cost_price)                                     AS margin_amount,
    o.order_status,
    CURRENT_TIMESTAMP                                                      AS loaded_at
FROM staging.order_items        oi
JOIN staging.orders              o   ON oi.order_id   = o.order_id
JOIN warehouse.dim_date          dd  ON o.order_date  = dd.date_actual
JOIN warehouse.dim_customer      dc  ON o.customer_id = dc.customer_id_src
JOIN warehouse.dim_product       dp  ON oi.product_id = dp.product_id_src
JOIN warehouse.dim_channel       dch ON o.channel     = dch.channel_name;
