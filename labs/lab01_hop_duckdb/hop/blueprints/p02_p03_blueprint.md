# Blueprint — p02_build_dims & p03_build_facts

## Objectif

Construire les dimensions et les tables de faits du data warehouse en utilisant des transforms `ExecSql` chaînés dans Apache Hop.

---

## Le transform ExecSql

`ExecSql` exécute du SQL arbitraire sur une connexion de base de données. Il ne lit ni n'émet de lignes — il exécute le SQL et passe le flux en aval.

| Paramètre          | Valeur à utiliser |
|--------------------|-------------------|
| Connection         | DuckDB_Lab1       |
| Execute each row   | N                 |
| Single statement   | N (permet plusieurs instructions séparées par `;`) |
| Replace variables  | N                 |

**SQL multi-instructions :** Séparer les instructions par un `;` et un retour à la ligne dans le champ SQL. Hop les exécute séquentiellement.

---

## p02 — Chaîne de construction des dimensions

```
[Start/Dummy] → [Build dim_date] → [Build dim_customer] → [Build dim_product] → [Build dim_channel] → [Build dim_geo]
```

Chaque transform fait un `TRUNCATE` de la table cible puis un `INSERT INTO ... SELECT ...`.

### Lignes attendues par dimension

| Dimension      | Script SQL            | Lignes attendues |
|----------------|-----------------------|------------------|
| dim_date       | sql/21_dim_date.sql   | 1096             |
| dim_customer   | sql/22_dim_customer.sql | = nb clients staging |
| dim_product    | sql/23_dim_product.sql  | = nb produits staging |
| dim_channel    | sql/24_dim_channel.sql  | 3 (Online, Store, Partner) |
| dim_geo        | sql/25_dim_geo.sql      | nb villes distinctes |

**Vérification dim_date :**
```sql
SELECT COUNT(*) FROM warehouse.dim_date;
-- Attendu : 1096

SELECT is_weekend FROM warehouse.dim_date WHERE date_actual = '2025-01-05';
-- Attendu : true (dimanche)
```

---

## p03 — Chaîne de construction des faits

```
[Start/Dummy] → [Build fact_sales] → [Build fact_stock]
```

### Diagramme de jointure fact_sales

```
staging.order_items (oi)
    JOIN staging.orders (o)           ON oi.order_id = o.order_id
    JOIN warehouse.dim_date (dd)      ON o.order_date = dd.date_actual
    JOIN warehouse.dim_customer (dc)  ON o.customer_id = dc.customer_id_src
    JOIN warehouse.dim_product (dp)   ON oi.product_id = dp.product_id_src
    JOIN warehouse.dim_channel (dch)  ON o.channel = dch.channel_name
→ warehouse.fact_sales
```

**Grain :** 1 ligne par `order_item_id`  
**Clé :** `order_item_id` = `sales_key`

### Mesures calculées dans fact_sales

| Mesure          | Formule                                          |
|-----------------|--------------------------------------------------|
| gross_amount    | quantity × sale_unit_price                       |
| net_amount      | quantity × sale_unit_price − discount_amount     |
| cost_amount     | quantity × cost_unit_price (dp.cost_price)       |
| margin_amount   | net_amount − cost_amount                         |

### Vérification fact_sales

```sql
-- Aucune clé FK nulle
SELECT COUNT(*) FROM warehouse.fact_sales
WHERE date_key IS NULL OR customer_key IS NULL OR product_key IS NULL;
-- Attendu : 0

-- Répartition par statut
SELECT order_status, COUNT(*), ROUND(SUM(net_amount),2)
FROM warehouse.fact_sales
GROUP BY order_status ORDER BY 3 DESC;
```

---

## Nom de connexion à utiliser

Tous les transforms ExecSql référencent : **`DuckDB_Lab1`**

Cette connexion est définie dans `hop/metadata/rdbms/DuckDB_Lab1.json` et pointe vers `${HOP_PROJECT_HOME}/duckdb/lab1.duckdb`.

---

## Notes pour l'utilisation en Hop GUI

1. Ouvrir le fichier `.hpl` dans Hop GUI
2. Cliquer droit sur chaque transform ExecSql → **Edit** pour voir/modifier le SQL
3. La connexion `DuckDB_Lab1` doit être visible dans **File → Connections**
4. Exécuter avec **Run → Run pipeline** (local)
5. Vérifier les métriques dans l'onglet **Preview** après exécution
