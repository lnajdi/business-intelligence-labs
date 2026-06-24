# Blueprint - p01_csv_to_staging — notes approfondies

> **La recette de construction** (flux des transforms + réglages clés du dialogue GUI) est
> dans `../../lab01_consignes.md`, **Partie A — Étape 1**. Ce blueprint ne garde que les
> notes approfondies et les pièges.
> Concepts Hop (projet, pipeline vs workflow, transform, Run) : `../../docs/apache_hop_concepts.md`.

## Objectif

Construire un pipeline Apache Hop qui charge les CSV sources vers `staging.*`. Cette couche est une landing zone typee : elle convertit les types, aligne les schemas et isole les rejets techniques. Elle ne normalise pas les villes, ne filtre pas les statuts metier et ne supprime pas les references orphelines.

![p01 CSV vers staging](../../docs/diagrams/p01_staging_canvas.png)

## Flow de la sous-pipeline CUSTOMERS

```text
[Read customers.csv]
        |
        v
[Validate customer_id]
        |TRUE
        v
[Select customer fields]
        |
        v
[Write staging.customers]

FALSE -> [Rejects customers]
```

## Transforms utilises

| Transform | Type | Role |
|-----------|------|------|
| Read customers.csv | CSVInput | Lire le fichier CSV avec les champs types |
| Validate customer_id | FilterRows | Rejeter les lignes techniquement inexploitables |
| Select customer fields | SelectValues | Aligner les noms, types et ordre des colonnes |
| Write staging.customers | TableOutput | Ecrire dans DuckDB, truncate avant chargement initial |
| Rejects customers | TextFileOutput | Journaliser les lignes rejetees |

## Definition des champs - CSVInput customers.csv

| Nom du champ | Type | Format | Trim |
|--------------|------|--------|------|
| customer_id | Integer | | none |
| customer_name | String | | none |
| email | String | | none |
| city | String | | both |
| country | String | | none |
| signup_date | Date | yyyy-MM-dd | none |
| segment | String | | none |

## Regles staging

Autorise :

- conversion de types ;
- validation de colonnes obligatoires ;
- rejets techniques ;
- deduplication seulement si necessaire pour eviter un echec de chargement.

Interdit dans `p01` :

- normalisation des villes ;
- enrichissement produit avec categories ;
- filtrage de statuts de commande ;
- suppression des orphelins ;
- calcul de KPI ou de mesures.

> **Le `Validate <id>` de staging n'est PAS le filtre des dimensions (p02).** Ici on ne rejette
> qu'un cas *technique* : la ligne n'a pas d'identifiant propre (`customer_id IS NULL`), donc elle
> est inexploitable comme enregistrement. Les rejets *metier/referentiels* (references orphelines,
> doublons de `customer_id`, statut invalide) sont traites plus tard, au chargement warehouse.
> Une meme condition n'est verifiee que dans une seule couche : p02 fait confiance a staging et
> ne re-teste pas le null. Bonne pratique : router les rejets (`reason_code = MISSING_KEY`) au lieu
> de les supprimer, pour que `chargees + rejetees = source`.

## Tables a charger

- `staging.customers`
- `staging.categories`
- `staging.products`
- `staging.orders`
- `staging.order_items`
- `staging.payments`
- `staging.stock_movements`
- `staging.budget` (`sales_budget.csv` : chargé en Partie A, utilisé en Partie B)

> Réglages détaillés du dialogue GUI : tableau « Réglages clés par transform » de la
> **Partie A — Étape 1** des consignes.

## Pieges courants

- Project Home mal defini : `${DATA_DIR}` et la connexion ne se resolvent pas (erreur n1).
- Les `Dummy` du squelette doivent etre remplaces par le vrai transform (ex. `Select Values`).
- Oublier Truncate `Y` : les lignes s'accumulent a chaque Run.
- Apres edition en GUI, re-sauvegarder pour que le XML reste valide.

## Notes importantes

- Le squelette `p01_csv_to_staging.hpl` ne montre que le flux customers. Ouvrez-le dans Hop GUI et ajoutez les autres flux.
- Les scripts SQL servent d'oracle de validation et de secours CLI. Le chemin principal du lab est Hop natif.
- Apres modification dans Hop GUI, re-sauvegardez le fichier pour que le XML soit valide.
