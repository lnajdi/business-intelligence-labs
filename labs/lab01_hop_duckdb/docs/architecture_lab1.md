# Architecture utilisee dans le Lab 1

## Architecture canonique

```text
CSV sources
      -> Hop native ETL
staging.*
      -> Hop native ETL
warehouse.*
      -> DuckDB SQL exploration / validation
```

![Roles Hop, DuckDB et SQL](diagrams/overview_architecture_roles.png)

DuckDB reste la base locale du lab. Apache Hop porte le chemin principal d'ETL : lecture des CSV, chargement de `staging.*`, puis transformation vers `warehouse.*`.

## Role des couches

- `data/raw/` : fichiers CSV sources.
- `staging.*` : landing zone typee. Les lignes y sont converties et alignees au schema, sans nettoyage metier.
- `warehouse.*` : couche dimensionnelle nettoyee et conformee. Les dimensions, faits, mappings de cles et calculs de mesures y sont construits.
- `control.*` : watermarks et metadonnees de chargement.

![Frontiere staging vs warehouse](diagrams/overview_staging_warehouse_boundary.png)

## Role de SQL

SQL sert a explorer, verifier et fournir un chemin CLI de secours. Il ne remplace pas le pipeline Hop natif attendu dans le lab.

## Ce qui est volontairement exclu du Lab 1

- dbt ;
- ClickHouse ;
- Power BI / Superset ;
- orchestration avancee ;
- gouvernance avancee ;
- SCD Type 2.
