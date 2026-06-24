# Pattern de chargement incremental - Lab 1

## Le probleme

Apres le chargement initial, de nouvelles donnees arrivent regulierement. Ici, le batch d'avril 2025 doit etre integre sans recharger manuellement tous les CSV historiques.

## Full load vs chargement incremental

| | Full load (`50_initial_full_load.sql`) | Incremental (`51_incremental_load.sql`) |
|---|---|---|
| Quand | une fois, au depart | a chaque nouveau batch |
| Source | tous les CSV historiques | seulement le batch (filtre `date > watermark`) |
| Dimensions (`p02`) | reconstruites (tables recreees + INSERT) | **non rejouees** |
| Staging | (re)charge complet | **append** du batch, dedup par cle naturelle |
| Faits (`p03`) | `TRUNCATE` + rebuild | `TRUNCATE` + rebuild de `fact_sales` |
| Watermark | initialise | mis a jour |
| Rejeu | idempotent | idempotent (no-op si pas de nouvelles donnees) |

## Trois couches, trois comportements

Le point qui deroute le plus : les trois couches ne se traitent pas de la meme facon, **volontairement**.

- **Dimensions** — construites **une seule fois** au full load (les tables sont recreees vides par `CREATE OR REPLACE TABLE` dans `20_create_warehouse_schema.sql`, puis remplies par un simple `INSERT` ; pas de TRUNCATE dans le SQL des dims). Le workflow incremental enchaine `p04 -> p03` **sans** `p02` : les dimensions ne sont pas rejouees. C'est correct **ici** parce que le batch d'avril n'introduit aucun nouveau client / produit / canal (clients 1-5, produits 101/102/104/106 existent deja). En production, un batch peut amener de nouveaux membres : il faudrait alors relancer `p02` (ou un update SCD) **avant** les faits, sinon les `Database Lookup` ressortent en cles NULL.
- **Staging** — archive brute : on **ajoute** (append) le batch, on ne jette jamais l'historique. La dedup par cle naturelle (`NOT EXISTS` / `Database Lookup`) rend le rejeu idempotent.
- **Faits** — donnees *calculees* : on **`TRUNCATE` + reconstruit** depuis tout le staging (qui inclut desormais le batch). En incremental, seul `fact_sales` est reconstruit (`fact_stock` n'est pas touche : le batch d'avril ne contient aucun mouvement de stock).

```text
dim_customer/product/channel   (p02 : full load uniquement -- PAS rejoue en incremental ;
                                ok car avril n'amene aucun nouveau membre)
        ^ lookups (resolution des cles)
        |
Batch avril (CSV)
   |  Filter: date > watermark          +- control.load_watermark -+
   v                                    | orders   = 2025-04-20    |
staging.orders/items/payments  --MAJ--> | payments = 2025-04-21    |
   |  (APPEND : on garde l'historique)  +--------------------------+
   v
warehouse.fact_sales   <-- TRUNCATE + REBUILD (p03, depuis tout le staging)
                           (fact_stock non reconstruit en incremental)
```

## La table watermark

```sql
-- control.load_watermark
table_name      VARCHAR PRIMARY KEY
last_load_dt    DATE
updated_at      TIMESTAMP
```

Le watermark stocke la date maximale connue dans `staging.*`. Le prochain chargement incremental filtre les fichiers batch avec `date > last_load_dt`.

```sql
SELECT COALESCE(MAX(last_load_dt), DATE '2000-01-01')
FROM control.load_watermark
WHERE table_name = 'orders';
```

## Idempotence

Le pipeline Hop doit eviter les doublons techniques lors d'une reexecution :

```text
batch CSV
  -> Select Values (types)
  -> Filter Rows (date > watermark)
  -> Database Lookup staging.<table> on natural key
  -> keep only lookup misses
  -> Table Output staging.<table>
```

Dans le chemin SQL de secours, le meme principe est exprime avec `NOT EXISTS`.

## Pourquoi fact_sales fait un TRUNCATE + rechargement complet

C'est l'asymetrie qui surprend : le **staging ajoute** mais les **faits sont reconstruits**. La raison tient a la nature des deux couches. Le staging est une **archive brute** : la valeur est de tout conserver, donc on append. `fact_sales` est une donnee **calculee** a partir de *tout* le staging (jointures sur dimensions, regles metier, mesures) : la facon la plus simple et la plus sure d'obtenir un resultat correct est de la recalculer entierement. Cela evite les problemes de cles de substitution orphelines et reste acceptable pour un petit jeu de donnees.

En production, on utiliserait plus souvent un `MERGE` ou un pattern d'upsert pour ne recalculer que les lignes touchees.

## Exemple chiffre (batch d'avril)

Apres full load : `fact_sales=176`, `fact_stock=22`, watermark `orders=2025-03-21`. Apres l'incremental :

- `staging.orders` : **+5 commandes** (1015-1019).
- `fact_sales` : **176 -> 182** (+6 `order_items` d'avril).
- watermarks : `orders=2025-04-20`, `payments=2025-04-21`.
- `fact_stock` : inchange (le batch d'avril n'a aucun mouvement de stock).

## Pieges courants

### Paiements en retard

Un paiement peut arriver apres la commande. Le watermark de `payments` doit donc rester independant de celui de `orders`.

### Commandes annulees

La commande `1019` dans `orders_april.csv` a le statut `Cancelled`. Elle est chargee dans `staging.orders` **et dans `fact_sales`** (c'est pourquoi l'incremental ajoute 6 lignes de fait et non 5). On ne l'ecarte qu'au niveau des **requetes analytiques** ; le fait, lui, garde la trace de toutes les lignes de commande.

### Reinitialisation

Si `50_initial_full_load.sql` est relance, le warehouse et les watermarks sont reconstruits. Le prochain incremental repart de la date maximale chargee.

## Sequence d'execution incrementale

```text
1. Lire orders_april.csv, order_items_april.csv, payments_april.csv
2. Convertir les types et aligner les schemas
3. Filtrer les lignes selon les watermarks orders/payments
4. Eviter les doublons techniques dans staging
5. Inserer les nouvelles lignes dans staging.*
6. Reconstruire warehouse.fact_sales via p03
7. Mettre a jour control.load_watermark
```
