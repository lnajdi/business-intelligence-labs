# Architecture utilisée dans le Lab 1

> **Portée de ce document :** cette architecture décrit la **Partie A** (ingestion + exploration).
> La **Partie B** prolonge le pipeline avec une couche staging, un modèle en étoile (warehouse),
> un chargement incrémental et une comparaison budget vs réalisé. Voir `star_schema_design.md`.

```text
CSV opérationnels
      ↓
Apache Hop pipeline
      ↓
DuckDB local
      ↓
SQL d'exploration
      ↓
Rapport qualité + premiers KPI
```

## Pourquoi cette architecture ?

- Les CSV simulent des exports de systèmes opérationnels.
- Apache Hop rend visible la logique d'ingestion.
- DuckDB permet d'analyser localement sans serveur.
- SQL reste le langage principal pour comprendre les données.
- Aucun modèle dimensionnel n'est demandé en **Partie A** (il est introduit en Partie B).

## Introduit seulement en Partie B

- couche staging (règles de qualité) ;
- schéma en étoile (dimensions + tables de faits) ;
- chargement incrémental (watermark) ;
- comparaison budget vs réalisé.

## Ce qui est volontairement exclu du Lab 1

- dbt ;
- ClickHouse ;
- Power BI / Superset ;
- orchestration avancée ;
- gouvernance avancée ;
- SCD Type 2 (historisation des dimensions).
