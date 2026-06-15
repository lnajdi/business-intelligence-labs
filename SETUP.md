# Guide d'installation

Ce guide prépare votre machine pour les labs BI.

## 1. Installer Git

Vérifier Git :

```bash
git --version
```

Si la commande est absente, installer Git depuis :

```text
https://git-scm.com/downloads
```

## 2. Récupérer le dépôt

Cloner le dépôt une fois :

```bash
git clone https://github.com/lnajdi/business-intelligence-labs.git
cd business-intelligence-labs
```

Avant chaque séance de lab, mettre à jour votre copie locale :

```bash
git pull
```

## 3. Installer DuckDB CLI

Vérifier DuckDB :

```bash
duckdb --version
```

Si la commande est absente ou ne fonctionne pas, installer DuckDB CLI depuis :

```text
https://duckdb.org/docs/installation/
```

Les labs utilisent des commandes de la CLI DuckDB telles que `.read` : le package Python seul
ne suffit pas pour le workflow officiel.

## 4. Installer Apache Hop

Installer Apache Hop Desktop :

```text
https://hop.apache.org/download/
```

Apache Hop 2.x récent requiert **Java 17 minimum** (**Java 21 recommandé** pour les dernières
versions ; Hop 2.10+ ne fonctionne plus avec Java 11). Vérifier votre version Java :

```bash
java -version
```

Après installation, vérifier que vous pouvez :

- ouvrir Hop GUI ;
- créer ou ouvrir un projet ;
- lire un fichier CSV.

Pour les connexions DuckDB dans Hop, télécharger le driver DuckDB JDBC depuis :

```text
https://duckdb.org/docs/stable/clients/java
```

Copier `duckdb-jdbc-*.jar` dans le dossier `lib/` utilisé par votre installation ou votre
projet Hop, puis redémarrer Hop.

## 5. Installer un éditeur

Utiliser VS Code, IntelliJ, Cursor, Sublime Text ou un autre éditeur de texte.

## 6. Tester l'installation du Lab 1

Depuis la racine du dépôt :

```bash
cd labs/lab01_hop_duckdb
duckdb duckdb/lab1.duckdb ".read sql/01_load_raw_tables.sql"
duckdb duckdb/lab1.duckdb
```

Dans DuckDB :

```sql
.tables raw.*
.quit
```

Si vous voyez les tables `raw`, la partie DuckDB de l'installation est prête.

## Notes

- Ne pas committer `duckdb/lab1.duckdb` : il est généré localement.
- Le lab se fait en séance ; aucun rendu n'est à committer dans le dépôt.
- Python est optionnel pour le Lab 1 et n'est pas requis pour le workflow officiel.
