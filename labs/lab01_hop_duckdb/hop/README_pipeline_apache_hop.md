# Guide Apache Hop — Pipeline d'ingestion Lab 1

## Objectif

Construire un pipeline visuel qui charge les CSV de `data/raw/` dans une base DuckDB locale.

## Pipeline recommandé

Créer un pipeline par table ou un pipeline global avec un bloc par fichier.

Pour chaque fichier CSV :

```text
CSV file input
  → Select values / Metadata
  → Data quality checks simples
  → Table output DuckDB
```

## Connexion DuckDB

Selon votre installation Hop, deux options sont possibles :

### Option A — Connexion JDBC DuckDB

1. Ajouter le driver DuckDB JDBC à Hop.
2. Créer une connexion vers `duckdb/lab1.duckdb`.
3. Utiliser `Table output` pour charger les tables.

### Option B — Export SQL ou staging intermédiaire

Si la connexion DuckDB n'est pas disponible dans Hop :

1. utiliser Hop pour valider et normaliser les CSV ;
2. exporter des CSV propres vers `data/processed/` ;
3. charger ensuite avec la CLI DuckDB :

```bash
duckdb duckdb/lab1.duckdb ".read sql/01_load_raw_tables.sql"
```

## Noms de tables attendus

```text
raw.customers
raw.categories
raw.products
raw.orders
raw.order_items
raw.payments
raw.stock_movements
```

## Contrôles Hop minimum

- présence des colonnes attendues ;
- types date et numériques ;
- valeurs vides sur identifiants ;
- rejet ou marquage des lignes invalides ;
- journalisation du nombre de lignes lues et chargées.

## Capture attendue dans le rendu

Inclure une capture du pipeline Hop avec :

- les inputs CSV ;
- les étapes de transformation ;
- la sortie DuckDB ou export processed ;
- le nombre de lignes traitées.
