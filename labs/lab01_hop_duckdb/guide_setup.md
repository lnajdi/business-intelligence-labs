# Guide setup — Lab 1 : Apache Hop + DuckDB

Ce guide est la **référence unique de mise en place** du Lab 1. Il rassemble en un seul
endroit les prérequis, l'installation, la création du projet Hop, la connexion DuckDB et la
création des schémas. **Une fois ce setup terminé, le lab lui-même se fait dans
`lab01_consignes.md`.**

> **Windows d'abord.** Les commandes sont données pour **Windows (PowerShell)** en
> premier, puis pour **Linux / macOS**. La majorité des postes étant sous Windows,
> suivez la colonne Windows sauf indication contraire.

> Pour les **concepts Hop** (pipeline, workflow, transform), voir
> `docs/apache_hop_concepts.md`. Ce guide est le **pas-à-pas opérationnel de setup** ; il
> renvoie vers ce document au lieu de le recopier.

## Vue d'ensemble

Le lab construit un ETL complet en deux parties :

- **Partie A** — Charger les CSV sources → `staging.*` dans DuckDB.
- **Partie B** — Transformer `staging.*` → schéma en étoile `warehouse.*`, chargement
  incrémental, budget vs réalisé.

```text
data/raw/ (CSV)
   -> Hop ETL (p01)        -> staging.*
   -> Hop ETL (p02..p05)   -> warehouse.*
```

![Rôles Hop et DuckDB](docs/diagrams/overview_architecture_roles.png)

---

## Compétences nécessaires

- SQL de base : `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, agrégations.
- Compréhension minimale des fichiers CSV.
- Différence conceptuelle entre système opérationnel et système analytique.
- Utilisation basique d'un terminal.

---

## Étape 0 — Installation & prérequis

| Logiciel | Rôle | Lien de téléchargement |
|---|---|---|
| Apache Hop | Ingestion visuelle (chemin officiel, pipeline GUI) | https://hop.apache.org/download/ |
| DuckDB CLI | Moteur d'exploration local (requêtes `.read`) | https://duckdb.org/docs/installation/ |
| Driver DuckDB JDBC | Connexion DuckDB depuis Hop (Partie B) | https://duckdb.org/docs/stable/clients/java |
| Git | Récupérer et mettre à jour le matériel | https://git-scm.com/downloads |
| Éditeur de texte | VS Code, IntelliJ, Cursor, Sublime Text… | https://code.visualstudio.com/ |

### Java 17+

Apache Hop requiert **Java 17 minimum** (**Java 21 recommandé**).

```powershell
java -version
```

Si Java est absent ou trop ancien, l'installer depuis https://adoptium.net.

### Apache Hop 2.x

Télécharger Apache Hop Desktop (version 2.x récente) depuis
https://hop.apache.org/download/ et le décompresser dans un dossier de votre choix.

| | Lancement de Hop GUI |
|---|---|
| **Windows** | double-clic sur `hop-gui.bat` (ou `.\hop-gui.bat` dans le dossier Hop) |
| **Linux / macOS** | `./hop-gui.sh` |

### DuckDB CLI

DuckDB est le **moteur d'exploration** du lab : une fois `staging.*` chargé, les analyses
se font avec la CLI.

**Windows (recommandé — winget) :**

```powershell
winget install DuckDB.cli
```

`winget` place `duckdb.exe` dans votre dossier utilisateur et l'ajoute **automatiquement
au PATH**. DuckDB sous Windows requiert le **Microsoft Visual C++ Redistributable** (déjà
présent sur la plupart des postes).

> **Important :** après l'installation, **ouvrez un nouveau terminal** pour que le PATH
> mis à jour soit pris en compte, puis vérifiez :

```powershell
duckdb --version
```

**Linux / macOS :** installer depuis https://duckdb.org/docs/installation/, puis
`duckdb --version`.

### Driver DuckDB JDBC (Partie B avec Hop)

Le driver JDBC permet à Hop de se connecter à DuckDB. **Il n'est pas fourni dans ce
dépôt** : il faut le télécharger.

1. Télécharger `duckdb-jdbc-*.jar` depuis https://duckdb.org/docs/stable/clients/java.
2. Le copier dans le dossier `lib/` de votre **installation Apache Hop** (ex.
   `…/hop/lib/`).
3. **Redémarrer Hop** pour qu'il prenne en compte le nouveau driver.

> Sans ce `.jar`, le **Test connection** de l'étape 2 échoue.

### Git & éditeur de texte

```powershell
git --version
```

Si la commande est absente, installer Git depuis https://git-scm.com/downloads. Pour
l'édition : VS Code, IntelliJ, Cursor, Sublime Text ou équivalent.

---

## Étape 1 — Créer le projet Hop *(étape à ne pas rater)*

1. Lancer Hop GUI.
2. **File → New Project**.
3. **Project Name** : `Lab1` (ou autre).
4. **Project Home** : le chemin **absolu** du dossier `labs/lab01_hop_duckdb`
   — c'est-à-dire **le dossier du lab lui-même, PAS le sous-dossier `hop/`**. Exemple :

   ```text
   <racine-du-dépôt>\labs\lab01_hop_duckdb
   ```

5. **Metadata base folder** *(crucial)* : par défaut Hop utilise
   `${PROJECT_HOME}/metadata`. **Or, dans ce dépôt, la métadonnée est rangée sous
   `hop/metadata/`.** Vous **devez** donc changer ce champ pour :

   ```text
   ${PROJECT_HOME}/hop/metadata
   ```

   Sinon la connexion `DuckDB_Lab1` (et toute la métadonnée) **ne sera pas trouvée**.
6. Valider (OK / Finish).

> **Pourquoi c'est important :** `${PROJECT_HOME}` est la variable que Hop utilise pour
> résoudre tous les chemins relatifs. Si le Project Home est faux, ou si le metadata base
> folder ne pointe pas vers `hop/metadata`, alors `${PROJECT_HOME}/duckdb/lab1.duckdb`,
> les chemins des pipelines et la connexion ne se résolvent pas. **C'est la cause
> d'erreur n°1 au démarrage** (voir `docs/apache_hop_concepts.md`).

---

## Étape 2 — Vérifier la connexion DuckDB

La connexion est déjà définie dans `hop/metadata/rdbms/DuckDB_Lab1.json` et pointe vers
`${PROJECT_HOME}/duckdb/lab1.duckdb` (le fichier `.duckdb` est créé au premier
chargement).

1. Ouvrir le panneau **Metadata** (barre latérale gauche).
2. Déplier **Relational Database Connections**.
3. Clic droit sur **`DuckDB_Lab1`** → **Test connection**.
4. Résultat attendu : **Connection successful**.

**En cas d'échec :**

- Vérifier que `duckdb-jdbc-*.jar` est bien dans le `lib/` de l'installation Hop.
- Redémarrer Hop après avoir copié le `.jar`.
- Vérifier que **Project Home** = `labs/lab01_hop_duckdb` (et **pas** le sous-dossier
  `hop/`), et que le metadata base folder pointe vers `${PROJECT_HOME}/hop/metadata`.

---

## Étape 3 — Création des schémas (une seule fois) + vérification

Avant de lancer un pipeline Hop, créer les schémas dans DuckDB. Se placer **dans** le
dossier du lab (les scripts utilisent des chemins relatifs) :

**Windows (PowerShell) :**

```powershell
cd labs/lab01_hop_duckdb

# Schémas (staging, warehouse, control)
duckdb duckdb/lab1.duckdb ".read sql/00_create_schema.sql"

# Structure des tables de staging
duckdb duckdb/lab1.duckdb ".read sql/10_create_staging_schema.sql"
```

**Linux / macOS :**

```bash
cd labs/lab01_hop_duckdb
duckdb duckdb/lab1.duckdb ".read sql/00_create_schema.sql"
duckdb duckdb/lab1.duckdb ".read sql/10_create_staging_schema.sql"
```

### Vérifier que les schémas existent

```powershell
duckdb duckdb/lab1.duckdb "SELECT * FROM information_schema.schemata;"
```

Vous devez voir apparaître `staging`, `warehouse` et `control` (en plus des schémas
système). Si l'un manque, relancer le script `00_create_schema.sql`.

> Les **séquences** et les tables du warehouse (`sql/20_create_warehouse_schema.sql`) ainsi
> que le schéma de contrôle (`sql/40_create_control_schema.sql`) sont créés au début de la
> Partie B — voir `lab01_consignes.md`.

---

## Étape 4 — Lancer le lab

Les schémas et la connexion sont prêts. **Le setup est terminé.** Suivez maintenant les
consignes du lab dans **`lab01_consignes.md`** :

- **Partie A** : ingestion des CSV vers `staging.*` avec Hop, puis exploration DuckDB.
  Guide pas-à-pas du premier flux : `hop/README_pipeline_apache_hop.md` et
  `hop/blueprints/p01_blueprint.md`.
- **Partie B** : schéma en étoile, chargement incrémental, budget vs réalisé. Réglages des
  transforms : `hop/blueprints/p02_p03_blueprint.md`, `p04_blueprint.md`, `p05_blueprint.md`.
  L'ordre opérationnel (pré-requis warehouse, dimensions, faits, workflows) est détaillé
  directement dans `lab01_consignes.md` (Partie B).

**Chemin de secours CLI** (si Hop est indisponible, ou pour vérifier les résultats) :

```powershell
duckdb duckdb/lab1.duckdb ".read sql/01_load_staging_tables.sql"   # Partie A : staging
duckdb duckdb/lab1.duckdb ".read sql/50_initial_full_load.sql"     # Partie B : chargement complet
duckdb duckdb/lab1.duckdb ".read sql/51_incremental_load.sql"      # Partie B : incrémental
duckdb duckdb/lab1.duckdb ".read sql/52_actuals_vs_budget.sql"     # Partie B : budget vs réalisé
```

> Les scripts SQL servent d'**oracle de validation** et de chemin de secours. Le chemin
> principal du lab reste **Hop natif** (transforms visibles sur le canvas).

---

## Préparation avant la séance

1. Décompresser le dossier du lab.
2. Ouvrir `data/raw/` et repérer les fichiers principaux, les fichiers `_april` et le fichier budget.
3. Lire `docs/data_dictionary.md`.
4. Lire `docs/business_questions.md`.
5. Préparer un dossier local de travail (aucun rendu n'est demandé : le lab se fait en séance).

## Note pédagogique

dbt n'est pas utilisé dans ce lab. Il sera introduit au Lab 2, après les séances sur la
modélisation dimensionnelle.
