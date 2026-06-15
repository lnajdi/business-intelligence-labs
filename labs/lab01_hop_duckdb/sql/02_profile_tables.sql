-- Profiling rapide des tables raw

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM raw.customers
UNION ALL SELECT 'categories', COUNT(*) FROM raw.categories
UNION ALL SELECT 'products', COUNT(*) FROM raw.products
UNION ALL SELECT 'orders', COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM raw.order_items
UNION ALL SELECT 'payments', COUNT(*) FROM raw.payments
UNION ALL SELECT 'stock_movements', COUNT(*) FROM raw.stock_movements
ORDER BY table_name;

-- Période couverte par les commandes
SELECT
  MIN(order_date) AS first_order_date,
  MAX(order_date) AS last_order_date,
  COUNT(DISTINCT order_id) AS orders_count
FROM raw.orders;

-- Distribution des statuts commande
SELECT order_status, COUNT(*) AS orders_count
FROM raw.orders
GROUP BY order_status
ORDER BY orders_count DESC;

-- Distribution des canaux
SELECT channel, COUNT(*) AS orders_count
FROM raw.orders
GROUP BY channel
ORDER BY orders_count DESC;

-- Distribution des méthodes de paiement
SELECT payment_method, payment_status, COUNT(*) AS payments_count, SUM(amount) AS total_amount
FROM raw.payments
GROUP BY payment_method, payment_status
ORDER BY payment_method, payment_status;
