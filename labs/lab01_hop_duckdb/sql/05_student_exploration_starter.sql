-- Starter SQL étudiant — compléter librement

-- 1. Choisissez une table et affichez 10 lignes.
SELECT *
FROM raw.orders
LIMIT 10;

-- 2. Vérifiez une clé unique.
SELECT
  order_id,
  COUNT(*) AS n
FROM raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Construisez votre propre KPI.
-- Exemple : CA par ville.
SELECT
  o.city,
  SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS net_revenue
FROM raw.orders o
JOIN raw.order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.city
ORDER BY net_revenue DESC;
