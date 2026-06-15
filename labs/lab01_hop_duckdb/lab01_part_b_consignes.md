# Lab 1 — Partie B : Transformation, Modélisation & Chargement

Cette partie est une extension de la Partie A. Elle suppose que les sources principales ont été comprises, que la base DuckDB locale est utilisable, et que les tables `raw.*` peuvent être recréées avec `sql/01_load_raw_tables.sql`.

## Pré-requis Hop

1. Ouvrir Apache Hop → **File → New Project**
2. **Project Home** = chemin absolu du dossier `labs/lab01_hop_duckdb` (ex: `C:\...\bi-course-labs\labs\lab01_hop_duckdb`)
3. La connexion `DuckDB_Lab1` est déjà définie dans `hop/metadata/rdbms/DuckDB_Lab1.json` — Hop la charge automatiquement
4. Télécharger `duckdb-jdbc-*.jar` depuis [duckdb.org](https://duckdb.org/docs/stable/clients/java) et le copier dans le dossier `lib/` du projet Hop
5. Vérifier la connexion : clic droit sur `DuckDB_Lab1` → **Test connection**

> La variable `${HOP_PROJECT_HOME}` est automatiquement résolue par Hop au chemin du projet. Le fichier DuckDB est à `duckdb/lab1.duckdb` dans ce dossier.

---

## Architecture des couches

```
data/raw/     (7 CSV principaux + batch avril + budget)
      ↓  staging transformations
staging.*     (6 tables : déduplication, normalisation, filtrage orphelins)
      ↓  modélisation dimensionnelle
warehouse.*   (5 dimensions + 2 tables de faits + 1 table budget)
control.*     (watermarks de chargement, log)
```

---

## Objectifs et livrables

### Partie B-1 — Couche staging (30 min)

Appliquer les règles de qualité sur les données brutes.

**Référence SQL :** `sql/10_create_staging_schema.sql` + `sql/11_staging_transformations.sql`

Règles appliquées :
- Clients : déduplication sur `customer_id`, normalisation des noms de villes
- Produits : enrichissement avec `category_name` depuis `raw.categories`
- Commandes : suppression des références clients orphelines et des statuts invalides
- Lignes de commandes : suppression des références orphelines, `quantity > 0`
- Paiements : `amount > 0`, références commandes valides
- Mouvements de stock : `movement_type IN ('IN','OUT')`, références produits valides

**Questions d'analyse :**
1. Combien de lignes ont été filtrées pour chaque table ?
2. Quelles villes ont été normalisées ? Combien de variantes existaient ?

---

### Partie B-2 — Modèle en étoile (30 min)

Construire le data warehouse dimensionnel.

**Référence SQL :** `sql/20_create_warehouse_schema.sql` + `sql/21_dim_date.sql` à `sql/31_fact_stock.sql`

**Schéma :**

```
dim_date ──────┐
dim_customer ──┤
dim_product ───┼──► fact_sales
dim_channel ───┤
               │
dim_date ──────┐
dim_product ───┴──► fact_stock

dim_channel ──────► fact_budget
```

Voir `docs/star_schema_design.md` pour l'ERD complet et les définitions de grain.

**Questions d'analyse :**
1. Quelle est la granularité de `fact_sales` ? de `fact_stock` ?
2. Pourquoi utilise-t-on des clés de substitution (`customer_key`) plutôt que les IDs sources ?

---

### Partie B-3 — Chargement initial (20 min)

> **Ordre d'exécution :** lancer les scripts dans l'ordre `50` → `51` → `52`, une seule fois chacun.
> Ne **pas** relancer `50_initial_full_load.sql` après `51` : il réinitialise le warehouse et le watermark
> (`control.load_watermark`), ce qui fausse le test incrémental. Si vous devez repartir de zéro,
> relancez `50`, puis `51`, puis `52` dans cet ordre.

Exécuter le script de chargement complet.

```bash
# Depuis le dossier labs/lab01_hop_duckdb
duckdb duckdb/lab1.duckdb ".read sql/50_initial_full_load.sql"
```

**Résultat attendu :**
```
FULL LOAD COMPLETE | fact_sales_rows=13 | fact_stock_rows=10 | fact_budget_rows=12 | latest_order_date=2025-03-21
```

**Validations :**
```sql
-- Aucune FK nulle dans fact_sales
SELECT COUNT(*) FROM warehouse.fact_sales
WHERE date_key IS NULL OR customer_key IS NULL OR product_key IS NULL;
-- Attendu : 0

-- dim_date couvre toutes les dates
SELECT COUNT(*) FROM staging.orders o
LEFT JOIN warehouse.dim_date dd ON o.order_date = dd.date_actual
WHERE dd.date_key IS NULL;
-- Attendu : 0

-- Budget chargé
SELECT COUNT(*) FROM warehouse.fact_budget;
-- Attendu : 12
```

---

### Partie B-4 — Chargement incrémental (30 min)

Simuler l'arrivée d'un nouveau batch (commandes d'avril 2025).

**Concept watermark :** La table `control.load_watermark` stocke la date du dernier chargement. Le script incrémental n'insère que les lignes **postérieures** à cette date.

```bash
duckdb duckdb/lab1.duckdb ".read sql/51_incremental_load.sql"
```

**Résultat attendu :**
```
INCREMENTAL LOAD COMPLETE | fact_sales_rows=19 | latest_order_date=2025-04-20
```

Le batch d'avril ajoute 5 commandes dans `staging.orders`, et 6 lignes supplémentaires dans `warehouse.fact_sales` après application des règles de qualité et reconstruction de la table de faits.

Voir `docs/incremental_load_pattern.md` pour les détails du pattern et les pièges.

**Questions d'analyse :**
1. Combien de lignes ont été ajoutées dans `staging.orders` ?
2. Pourquoi `fact_sales` fait-il un `TRUNCATE` + rechargement complet plutôt qu'un append ?

---

### Partie B-5 — Budget vs Réalisé (20 min)

Comparer les ventes réelles aux objectifs budgétaires.

```bash
duckdb duckdb/lab1.duckdb ".read sql/52_actuals_vs_budget.sql"
```

**Questions d'analyse :**
1. Quel mois/catégorie a le meilleur taux d'atteinte du budget ?
2. Que signifie un `achievement_pct` NULL ?

---

### Partie B-6 — Pipeline Hop (60 min)

Construire visuellement le pipeline `p01_raw_to_staging` dans Apache Hop GUI.

**Guide :** `hop/blueprints/p01_blueprint.md`

Le squelette fourni dans `hop/pipelines/p01_raw_to_staging.hpl` montre le flux customers. Vous devez :
1. Ouvrir le fichier dans Hop GUI
2. Ajouter les 5 autres flux (orders, order_items, payments, products, stock_movements)
3. Tester la connexion `DuckDB_Lab1`
4. Exécuter le workflow `hop/workflows/wf_initial_load.hwf`
5. Vérifier que le résultat dans `warehouse.fact_sales` correspond au résultat SQL

**Note importante :** Les scripts SQL (`sql/11_staging_transformations.sql`) sont la référence officielle. Le pipeline Hop `p01` enseigne visuellement les mêmes opérations mais utilise une approche simplifiée pour la déduplication (filtrage direct vs `ROW_NUMBER() OVER`). Les deux doivent produire la même table `staging.customers` finale sur ce jeu de données.

---

## À produire pendant la séance (non rendu)

Aucun rendu n'est à remettre. En fin de séance, vous devriez avoir réalisé sur votre poste :

- [ ] le pipeline `p01_raw_to_staging` complété dans Hop GUI (les 6 flux)
- [ ] le workflow `wf_initial_load` exécuté avec succès (actions en vert)
- [ ] le résultat de la requête `52_actuals_vs_budget.sql`
- [ ] vos réponses aux questions d'analyse des parties B-1 à B-5

---

## Ressources

| Fichier | Description |
|---------|-------------|
| `sql/50_initial_full_load.sql` | Script d'orchestration complet |
| `docs/star_schema_design.md` | ERD et définitions de grain |
| `docs/incremental_load_pattern.md` | Pattern watermark et pièges |
| `hop/blueprints/p01_blueprint.md` | Guide étape par étape pour p01 |
| `hop/blueprints/p02_p03_blueprint.md` | Guide pour dimensions et faits |
| `hop/blueprints/p04_blueprint.md` | Guide pour le chargement incrémental |
