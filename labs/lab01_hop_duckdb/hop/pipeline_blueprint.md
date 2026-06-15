# Blueprint de pipeline Hop — Référence rapide Partie A

> Résumé visuel pour l'ingestion CSV → `raw.*` (Étape 1 de `lab01_part_a_consignes.md`).
> Pour le guide détaillé étape par étape, voir `hop/blueprints/p01_blueprint.md`.

## Version simple

```text
customers.csv        → raw.customers
categories.csv       → raw.categories
products.csv         → raw.products
orders.csv           → raw.orders
order_items.csv      → raw.order_items
payments.csv         → raw.payments
stock_movements.csv  → raw.stock_movements
```

## Version avec contrôles

```text
CSV input
  → validate required columns
  → cast dates and numbers
  → flag invalid rows
  → output valid rows to DuckDB
  → output rejected rows to data/processed/rejects_<table>.csv
```

## Colonnes critiques par table

| Table | Colonnes critiques |
|---|---|
| customers | customer_id, customer_name |
| categories | category_id, category_name |
| products | product_id, category_id, unit_price |
| orders | order_id, customer_id, order_date, order_status |
| order_items | order_item_id, order_id, product_id, quantity, unit_price |
| payments | payment_id, order_id, payment_status, amount |
| stock_movements | movement_id, product_id, movement_type, quantity |
