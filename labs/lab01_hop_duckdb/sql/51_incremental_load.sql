-- sql/51_incremental_load.sql
-- Appends April 2025 batch to raw, then to staging (watermark-filtered),
-- then rebuilds fact_sales.

-- 1. Register new batch files as raw tables (idempotent)
CREATE TABLE IF NOT EXISTS raw.orders_batch2 AS
    SELECT * FROM read_csv_auto('data/raw/orders_april.csv', header=true);
CREATE TABLE IF NOT EXISTS raw.order_items_batch2 AS
    SELECT * FROM read_csv_auto('data/raw/order_items_april.csv', header=true);
CREATE TABLE IF NOT EXISTS raw.payments_batch2 AS
    SELECT * FROM read_csv_auto('data/raw/payments_april.csv', header=true);

-- 2. Append to raw.orders (dedup by order_id)
-- NOT IN is safe here: order_id is never NULL in the batch file.
-- In general prefer NOT EXISTS or LEFT JOIN / IS NULL to avoid NULL-set traps.
INSERT INTO raw.orders
SELECT * FROM raw.orders_batch2
WHERE order_id NOT IN (SELECT order_id FROM raw.orders);

INSERT INTO raw.order_items
SELECT * FROM raw.order_items_batch2
WHERE order_item_id NOT IN (SELECT order_item_id FROM raw.order_items);

INSERT INTO raw.payments
SELECT * FROM raw.payments_batch2
WHERE payment_id NOT IN (SELECT payment_id FROM raw.payments);

-- 3. Append to staging.orders (only rows after watermark)
INSERT OR IGNORE INTO staging.orders
SELECT o.*
FROM raw.orders o
INNER JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE o.order_date > (
    SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
    FROM control.load_watermark WHERE table_name = 'orders'
)
AND o.order_id IS NOT NULL
AND o.order_status IN ('Completed','Returned','Cancelled','Shipped');

INSERT OR IGNORE INTO staging.order_items
SELECT oi.*
FROM raw.order_items oi
INNER JOIN staging.orders   o ON oi.order_id   = o.order_id
INNER JOIN staging.products p ON oi.product_id = p.product_id
WHERE oi.quantity > 0 AND oi.unit_price >= 0
  AND oi.order_item_id NOT IN (SELECT order_item_id FROM staging.order_items);

INSERT OR IGNORE INTO staging.payments
SELECT pm.*
FROM raw.payments pm
INNER JOIN staging.orders o ON pm.order_id = o.order_id
WHERE pm.amount > 0
  AND pm.payment_id NOT IN (SELECT payment_id FROM staging.payments);

-- 4. Rebuild fact_sales (full refresh — simpler for this lab)
.read sql/30_fact_sales.sql

-- 5. Update watermarks
INSERT OR REPLACE INTO control.load_watermark(table_name, last_load_dt, updated_at)
SELECT 'orders', MAX(order_date), CURRENT_TIMESTAMP FROM staging.orders
UNION ALL
SELECT 'payments', MAX(payment_date), CURRENT_TIMESTAMP FROM staging.payments;

SELECT 'INCREMENTAL LOAD COMPLETE' AS status,
       (SELECT COUNT(*) FROM warehouse.fact_sales)   AS fact_sales_rows,
       (SELECT MAX(order_date) FROM staging.orders)  AS latest_order_date;
