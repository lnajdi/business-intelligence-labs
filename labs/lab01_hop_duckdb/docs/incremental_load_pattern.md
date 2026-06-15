# Pattern de chargement incrémental — Lab 1

## Le problème

Après le chargement initial, de nouvelles données arrivent régulièrement (ici : commandes d'avril 2025). Il faut les intégrer sans recharger l'intégralité des données historiques.

---

## La table watermark

```sql
-- control.load_watermark
table_name      VARCHAR PRIMARY KEY   -- ex: 'orders'
last_load_dt    DATE                  -- date max chargée lors du dernier run
updated_at      TIMESTAMP
```

Le watermark stocke la **date maximale** connue dans staging. Le prochain chargement incrémental filtre `WHERE order_date > last_load_dt`.

### Initialisation après chargement initial

```sql
INSERT OR REPLACE INTO control.load_watermark(table_name, last_load_dt)
SELECT 'orders', MAX(order_date) FROM staging.orders;
```

---

## Garantie d'idempotence

`INSERT OR IGNORE` (DuckDB) + filtrage explicite par PK garantit qu'une ré-exécution du script incrémental n'insère pas de doublons :

```sql
INSERT OR IGNORE INTO staging.orders
SELECT o.* FROM raw.orders o
WHERE o.order_date > (SELECT last_load_dt FROM control.load_watermark WHERE table_name='orders')
  AND o.order_id IS NOT NULL ...;
```

Si le script est relancé après interruption, les lignes déjà insérées sont ignorées (contrainte PRIMARY KEY).

---

## Pourquoi fact_sales fait un TRUNCATE + rechargement complet

Dans ce lab, `fact_sales` est **recalculée entièrement** après chaque chargement incrémental (`30_fact_sales.sql` est rappelé). Ce choix :

- **Simplifie** le code pour un lab pédagogique
- **Évite** les problèmes de clés de substitution orphelines
- **Reste acceptable** à l'échelle du jeu de données (< 100 lignes)

**En production**, on utiliserait un pattern MERGE (UPSERT) :

```sql
-- Pattern production (non implémenté dans ce lab)
MERGE INTO warehouse.fact_sales AS target
USING (SELECT ... FROM staging.order_items WHERE ...) AS source
ON target.sales_key = source.sales_key
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT VALUES ...;
```

---

## Pièges courants

### 1. Paiements en retard (late-arriving payments)

Un paiement peut arriver avec une date postérieure à celle de sa commande. Le watermark de `payments` doit être indépendant de celui de `orders`. Le script `51_incremental_load.sql` maintient des watermarks séparés.

```sql
-- Watermark payments mis à jour indépendamment
SELECT 'payments', MAX(payment_date), CURRENT_TIMESTAMP FROM staging.payments
```

### 2. Fuseaux horaires et dates

DuckDB stocke les `DATE` sans information de fuseau horaire. Si les CSVs source proviennent de systèmes en UTC+1 (Maroc), une commande passée à 23h30 heure locale peut avoir une date UTC du lendemain. Pour ce lab, toutes les dates sont en heure locale — pas de problème.

### 3. Commandes annulées dans le batch incrémental

La commande `1019` dans `orders_april.csv` a le statut `Cancelled`. Elle est bien chargée dans `staging.orders` et reste présente dans `warehouse.fact_sales` avec son statut, car `fact_sales` conserve les lignes de commande valides au grain ligne de commande. Les requêtes de chiffre d'affaires réalisé doivent filtrer `WHERE order_status = 'Completed'` pour exclure les commandes annulées, retournées ou non finalisées.

### 4. Réinitialisation des watermarks

Si les données sont rechargées depuis zéro (ex: `50_initial_full_load.sql` ré-exécuté), les watermarks dans `control.load_watermark` sont mis à jour par `40_create_control_schema.sql`. Le prochain chargement incrémental repartira bien de la bonne date.

---

## Comparaison des approches

| Approche              | Complexité | Idempotence | Adapté à ce lab |
|-----------------------|------------|-------------|-----------------|
| Full reload           | Faible     | Oui         | Pour petits volumes |
| Watermark + append    | Moyenne    | Avec IGNORE  | **Oui — implémenté** |
| MERGE/UPSERT          | Élevée     | Oui         | Production |
| CDC (Change Data Capture) | Très élevée | Oui    | Systèmes temps réel |

---

## Séquence d'exécution incrémentale

```
1. Charger les fichiers batch → raw.orders_batch2, raw.order_items_batch2, raw.payments_batch2
2. Append dans raw.orders / raw.order_items / raw.payments (dédup par PK)
3. Append dans staging.orders (filtrage watermark + règles qualité)
4. Append dans staging.order_items (référence orders valides)
5. Append dans staging.payments (référence orders valides)
6. Reconstruire warehouse.fact_sales (TRUNCATE + INSERT complet)
7. Mettre à jour control.load_watermark
```
