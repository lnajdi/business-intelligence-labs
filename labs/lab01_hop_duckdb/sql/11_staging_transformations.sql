-- sql/11_staging_transformations.sql
-- Reference implementation for staging. Hop p01 demonstrates the same
-- operations visually but uses a simplified approach without window dedup.

-- CUSTOMERS: deduplicate by customer_id (keep earliest signup), normalize city
INSERT OR REPLACE INTO staging.customers
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date) AS rn
    FROM raw.customers
    WHERE customer_id IS NOT NULL AND customer_name IS NOT NULL
)
SELECT
    customer_id,
    customer_name,
    NULLIF(TRIM(email), '')  AS email,
    CASE UPPER(TRIM(city))
        WHEN 'CASABLANCA'  THEN 'Casablanca'
        WHEN 'RABAT'       THEN 'Rabat'
        WHEN 'MARRAKECH'   THEN 'Marrakech'
        WHEN 'FES'         THEN 'Fes'
        WHEN 'FEZ'         THEN 'Fes'
        WHEN 'TANGIER'     THEN 'Tangier'
        WHEN 'TANGER'      THEN 'Tangier'
        WHEN 'AGADIR'      THEN 'Agadir'
        ELSE 'Unknown'
    END  AS city,
    country,
    signup_date,
    segment
FROM deduped
WHERE rn = 1;

-- PRODUCTS: enrich with category name
INSERT OR REPLACE INTO staging.products
SELECT
    p.product_id,
    p.product_name,
    p.category_id,
    c.category_name,
    c.department,
    p.unit_price,
    p.cost_price,
    p.active_flag
FROM raw.products p
LEFT JOIN raw.categories c ON p.category_id = c.category_id
WHERE p.product_id IS NOT NULL;

-- ORDERS: drop orphaned customer references + invalid statuses
INSERT OR REPLACE INTO staging.orders
SELECT o.*
FROM raw.orders o
INNER JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE o.order_id IS NOT NULL
  AND o.order_date IS NOT NULL
  AND o.order_status IN ('Completed','Returned','Cancelled','Shipped');

-- ORDER ITEMS: drop orphaned product/order references + invalid quantities
INSERT OR REPLACE INTO staging.order_items
SELECT oi.*
FROM raw.order_items oi
INNER JOIN staging.orders   o ON oi.order_id   = o.order_id
INNER JOIN staging.products p ON oi.product_id = p.product_id
WHERE oi.quantity > 0
  AND oi.unit_price >= 0;

-- PAYMENTS: drop orphaned order references + non-positive amounts
INSERT OR REPLACE INTO staging.payments
SELECT pm.*
FROM raw.payments pm
INNER JOIN staging.orders o ON pm.order_id = o.order_id
WHERE pm.amount > 0;

-- STOCK MOVEMENTS: drop orphaned product references
INSERT OR REPLACE INTO staging.stock_movements
SELECT sm.*
FROM raw.stock_movements sm
INNER JOIN staging.products p ON sm.product_id = p.product_id
WHERE sm.quantity > 0
  AND sm.movement_type IN ('IN','OUT');
