# Blueprint - p02_build_dims & p03_build_facts

## Objectif

Construire les dimensions et les tables de faits avec des transforms Hop natifs. Les scripts SQL equivalents restent un oracle de validation, mais ils ne sont pas le workflow principal.

`ExecSql` est limite au plumbing : `TRUNCATE`, creation de tables techniques, mise a jour de `control.*`. Les jointures, filtres, deduplications, lookups, cles de substitution et calculs de mesures doivent etre visibles dans le canvas Hop.

## p02 - Dimensions

### dim_date

Pattern conseille :

```text
Generate Rows / Generate Sequence
  -> Calculator (date_key, year, quarter, month, day, weekday, is_weekend, season)
  -> Table Output warehouse.dim_date
```

Pour ce lab, un `ExecSql` de generation de calendrier est acceptable si Hop ne fournit pas facilement la generation de dates. Le reste des dimensions doit rester Hop-native.

### dim_customer

```text
Table Input staging.customers
  -> Filter Rows (customer_id and customer_name not null)
  -> Sort Rows (customer_id, signup_date)
  -> Unique Rows (deduplicate customer_id)
  -> Value Mapper / Select Values (city normalization, email default)
  -> Add Sequence (customer_key)
  -> Table Output warehouse.dim_customer
```

### dim_product

```text
Table Input staging.products
  -> Database Lookup staging.categories on category_id
  -> Filter Rows (product_id not null)
  -> Add Sequence (product_key)
  -> Table Output warehouse.dim_product
```

### dim_channel

```text
Table Input staging.orders
  -> Unique Rows (channel)
  -> Value Mapper (channel_type)
  -> Add Sequence (channel_key)
  -> Table Output warehouse.dim_channel
```

## p03 - Faits

### fact_sales

```text
Table Input staging.order_items
  -> Database Lookup staging.orders on order_id
  -> Database Lookup warehouse.dim_date on order_date
  -> Database Lookup warehouse.dim_customer on customer_id
  -> Database Lookup warehouse.dim_product on product_id
  -> Database Lookup warehouse.dim_channel on channel
  -> Filter Rows (valid keys, valid status, quantity > 0, unit_price >= 0)
  -> Calculator (gross_amount, net_amount, cost_amount, margin_amount)
  -> Table Output warehouse.fact_sales
```

Grain : 1 ligne par `order_item_id`.  
Cle : `sales_key` est une cle de substitution generee dans le warehouse (Add Sequence). `order_item_id` est conserve comme `order_item_id_src` pour la tracabilite.

### fact_stock

```text
Table Input staging.stock_movements
  -> Database Lookup warehouse.dim_date on movement_date
  -> Database Lookup warehouse.dim_product on product_id
  -> Filter Rows (movement_type IN, quantity > 0)
  -> Calculator (qty_in, qty_out)
  -> Table Output warehouse.fact_stock
```

## Verifications

```sql
SELECT COUNT(*) FROM warehouse.dim_date;
-- Attendu : 1096

SELECT COUNT(*) FROM warehouse.fact_sales
WHERE date_key IS NULL OR customer_key IS NULL OR product_key IS NULL;
-- Attendu : 0

SELECT order_status, COUNT(*), ROUND(SUM(net_amount),2)
FROM warehouse.fact_sales
GROUP BY order_status
ORDER BY 3 DESC;
```

## Notes Hop GUI

1. Truncatez les tables cibles avant de recharger une dimension ou un fait.
2. Preferez `Database Lookup` ou `Stream Lookup` aux jointures SQL.
3. Utilisez `Calculator` pour les mesures, pas une expression SQL cachee.
4. Verifiez les compteurs de lignes entre chaque transform pendant la construction.
