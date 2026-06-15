# Guide Apache Hop - Pipeline d'ingestion Lab 1

## Objectif

Construire un pipeline visuel qui charge les CSV de `data/raw/` dans `staging.*` dans DuckDB.

## Pipeline recommande

Pour chaque fichier CSV :

```text
CSV file input
  -> Select Values / Metadata
  -> controles techniques simples
  -> Table Output DuckDB staging.<table>
```

La couche staging est une copie typee minimale des sources. Ne pas y appliquer de normalisation metier, de deduplication analytique, de filtrage d'orphelins ou de calculs de mesures.

## Connexion DuckDB

### Option A - Connexion JDBC DuckDB

1. Ajouter le driver DuckDB JDBC a Hop.
2. Creer une connexion vers `duckdb/lab1.duckdb`.
3. Utiliser `Table Output` pour charger les tables `staging.*`.

### Option B - Secours CLI

Si la connexion DuckDB n'est pas disponible dans Hop, charger les memes tables avec DuckDB CLI :

```bash
duckdb duckdb/lab1.duckdb ".read sql/10_create_staging_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/01_load_staging_tables.sql"
```

## Noms de tables attendus

```text
staging.customers
staging.categories
staging.products
staging.orders
staging.order_items
staging.payments
staging.stock_movements
staging.budget          # source Partie B (sales_budget.csv)
```

## Controles Hop minimum

- presence des colonnes attendues ;
- conversions de dates et nombres ;
- valeurs vides sur identifiants techniques ;
- rejet ou marquage des lignes illisibles ;
- journalisation du nombre de lignes lues et chargees.
