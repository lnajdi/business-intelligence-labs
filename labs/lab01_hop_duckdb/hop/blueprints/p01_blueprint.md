# Blueprint — p01_raw_to_staging

## Objectif

Construire un pipeline Apache Hop qui charge 6 fichiers CSV bruts vers le schéma `staging` en appliquant une validation des clés et une normalisation des villes.

---

## Flow de la sous-pipeline CUSTOMERS

```
[Read customers.csv]
        |
        v
[Validate customer_id]  --FALSE--> [Rejects customers]
        |TRUE
        v
[Normalize city]
        |
        v
[Write staging.customers]
```

---

## Transforms utilisés

| Transform        | Type            | Rôle                                            |
|------------------|-----------------|-------------------------------------------------|
| Read customers.csv | CSVInput       | Lire le fichier CSV avec les champs typés       |
| Validate customer_id | FilterRows   | Rejeter les lignes sans customer_id             |
| Normalize city   | ValueMapper     | Uniformiser les variantes de noms de villes     |
| Write staging.customers | TableOutput | Écrire en base DuckDB, truncate avant chargement|
| Rejects customers | TextFileOutput  | Journaliser les lignes rejetées                 |

---

## Définition des champs — CSVInput (customers.csv)

| Nom du champ  | Type    | Format     | Trim  |
|---------------|---------|------------|-------|
| customer_id   | Integer |            | none  |
| customer_name | String  |            | none  |
| email         | String  |            | none  |
| city          | String  |            | both  |
| country       | String  |            | none  |
| signup_date   | Date    | yyyy-MM-dd | none  |
| segment       | String  |            | none  |

---

## Condition FilterRows — IS NOT NULL

```
Leftvalue  : customer_id
Function   : IS NOT NULL
Rightvalue : (vide)
Negated    : N
```

`send_true_to` → Normalize city  
`send_false_to` → Rejects customers

---

## ValueMapper — Normalisation des villes

| Source value | Target value |
|--------------|--------------|
| CASABLANCA   | Casablanca   |
| casablanca   | Casablanca   |
| RABAT        | Rabat        |
| Rabat        | Rabat        |
| MARRAKECH    | Marrakech    |
| Marrakech    | Marrakech    |
| FES          | Fes          |
| FEZ          | Fes          |
| TANGIER      | Tangier      |
| TANGER       | Tangier      |
| AGADIR       | Agadir       |

**Field to use:** `city`  
**Target field:** `city` (remplacement sur place)  
**Non-match default:** `Unknown`

---

## TableOutput — staging.customers

| Paramètre         | Valeur          |
|-------------------|-----------------|
| Connection        | DuckDB_Lab1     |
| Schema            | staging         |
| Table             | customers       |
| Truncate table    | Y               |
| Specify fields    | N               |
| Commit size       | 1000            |
| Use batch update  | Y               |

---

## TextFileOutput — Rejects

| Paramètre | Valeur                              |
|-----------|-------------------------------------|
| Filename  | data/processed/rejects_customers    |
| Extension | csv                                 |
| Header    | Y                                   |
| Format    | UNIX                                |
| Encoding  | UTF-8                               |

---

## Checklist d'extension aux 5 autres tables

Reproduire le même patron pour chaque table en adaptant :

- [ ] **orders** — `order_id IS NOT NULL`, normaliser `order_status` IN liste valide, `send_false_to` → Rejects orders
- [ ] **order_items** — `order_item_id IS NOT NULL`, filter `quantity > 0`
- [ ] **payments** — `payment_id IS NOT NULL`, filter `amount > 0`
- [ ] **products** — `product_id IS NOT NULL`, pas de ValueMapper requis
- [ ] **stock_movements** — `movement_id IS NOT NULL`, filter `movement_type IN ('IN','OUT')`

Pour chaque extension :
1. Ajouter un transform CSVInput avec le fichier correspondant
2. Ajouter un FilterRows avec la condition de validation primaire
3. Connecter au TableOutput correspondant (`staging.<table>`, truncate=Y)
4. Connecter le faux-branche à un TextFileOutput rejects

---

## Notes importantes

- Le squelette `p01_raw_to_staging.hpl` ne montre que le flux customers. **Vous devez l'ouvrir dans Hop GUI et ajouter les 5 autres flux.**
- La référence SQL `11_staging_transformations.sql` fait une déduplication par fenêtre (`ROW_NUMBER() OVER`). Ce transform Hop utilise une approche simplifiée (filtre sur clé primaire). Les deux produisent le même résultat final sur ce jeu de données.
- Après modification dans Hop GUI, **re-sauvegarder le fichier** pour que le XML soit valide.
