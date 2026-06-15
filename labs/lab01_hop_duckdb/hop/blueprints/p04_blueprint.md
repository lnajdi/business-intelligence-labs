# Blueprint — p04_incremental_load

## Objectif

Charger un batch incrémental (commandes d'avril 2025) dans le pipeline en utilisant le pattern watermark : seules les lignes nouvelles (après la dernière date de chargement connue) sont insérées dans staging.

---

## Flow

```
[Start] → [Register batch files] → [Append raw orders]
       → [Append staging orders] → [Append staging order_items + payments]
       → [Update watermarks]
```

---

## Étape 1 — Enregistrer les fichiers batch comme tables raw

```sql
CREATE TABLE IF NOT EXISTS raw.orders_batch2 AS
    SELECT * FROM read_csv_auto('data/raw/orders_april.csv', header=true);
-- Répéter pour order_items_batch2 et payments_batch2
```

`CREATE TABLE IF NOT EXISTS` rend l'opération idempotente : ré-exécuter ne crée pas de doublon.

---

## Étape 2 — Append dans raw (dédup par PK)

```sql
INSERT INTO raw.orders
SELECT * FROM raw.orders_batch2
WHERE order_id NOT IN (SELECT order_id FROM raw.orders);
```

Pattern identique pour `order_items` et `payments`.

---

## Étape 3 — Append dans staging (filtrage watermark)

```sql
INSERT OR IGNORE INTO staging.orders
SELECT o.*
FROM raw.orders o
INNER JOIN staging.customers c ON o.customer_id = c.customer_id
WHERE o.order_date > (
    SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
    FROM control.load_watermark WHERE table_name = 'orders'
)
AND o.order_status IN ('Completed','Returned','Cancelled','Shipped');
```

Le watermark `control.load_watermark` contient la date du dernier chargement. Seules les lignes **après** cette date sont insérées.

---

## Étape 4 — Mise à jour des watermarks

```sql
INSERT OR REPLACE INTO control.load_watermark(table_name, last_load_dt, updated_at)
SELECT 'orders', MAX(order_date), CURRENT_TIMESTAMP FROM staging.orders
UNION ALL
SELECT 'payments', MAX(payment_date), CURRENT_TIMESTAMP FROM staging.payments;
```

---

## Vérification après exécution

```sql
-- Nouvelles commandes chargées
SELECT order_date, COUNT(*) FROM staging.orders
WHERE order_date >= '2025-04-01'
GROUP BY order_date ORDER BY order_date;

-- Watermark mis à jour
SELECT * FROM control.load_watermark ORDER BY table_name;
-- Attendu : orders → 2025-04-20, payments → 2025-04-21

-- fact_sales après reconstruction
SELECT COUNT(*) FROM warehouse.fact_sales;
-- Attendu : lignes initiales + 5 nouvelles lignes (hors Cancelled si filtré)
```

---

## Note

p04 est suivi de p03 dans le workflow `wf_incremental_load.hwf` pour reconstruire `fact_sales` et `fact_stock` avec les nouvelles données staging.
