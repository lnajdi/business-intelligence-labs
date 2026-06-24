-- sql/20_create_warehouse_schema.sql

CREATE SCHEMA IF NOT EXISTS warehouse;

-- SURROGATE-KEY SEQUENCES
-- Les clés de substitution sont frappées par la BASE (DEFAULT nextval), pas par
-- un transform Hop `Add Sequence`. Le minting de clé est du *plumbing* : la logique
-- métier (dédup, normalisation, lookup, filtre) reste sur le canvas Hop.
-- `CREATE OR REPLACE SEQUENCE` repart à START 1 à chaque (re)création du schéma
-- -> clés déterministes sur rechargement complet. La séquence doit exister AVANT
-- la table qui la référence en DEFAULT.
-- Exemptés : dim_date.date_key (YYYYMMDD calculé) et fact_budget.budget_id (clé
-- naturelle source) -> ce sont des clés naturelles, pas des substitutions.
CREATE OR REPLACE SEQUENCE warehouse.seq_dim_customer START 1;
CREATE OR REPLACE SEQUENCE warehouse.seq_dim_product  START 1;
CREATE OR REPLACE SEQUENCE warehouse.seq_dim_channel  START 1;
CREATE OR REPLACE SEQUENCE warehouse.seq_fact_sales   START 1;
CREATE OR REPLACE SEQUENCE warehouse.seq_fact_stock   START 1;

-- DIMENSIONS
CREATE OR REPLACE TABLE warehouse.dim_date (
    date_key     INTEGER PRIMARY KEY,  -- YYYYMMDD computed integer (clé naturelle)
    date_actual  DATE,
    year         INTEGER,
    quarter      INTEGER,
    month_num    INTEGER,
    month_name   VARCHAR,
    day_num      INTEGER,
    day_name     VARCHAR,
    day_of_week  INTEGER,             -- 0=Sunday ... 6=Saturday (DuckDB convention)
    is_weekend   BOOLEAN,
    season       VARCHAR
);

CREATE OR REPLACE TABLE warehouse.dim_customer (
    customer_key    INTEGER PRIMARY KEY DEFAULT nextval('warehouse.seq_dim_customer'),
    customer_id_src INTEGER,
    customer_name   VARCHAR,
    email           VARCHAR,
    city            VARCHAR,
    region          VARCHAR,           -- enrichissement : roll-up géographique (ville -> région)
    country         VARCHAR,           -- code source (ex. 'MA')
    country_name    VARCHAR,           -- enrichissement : code -> nom complet (MA -> Morocco)
    signup_date     DATE,
    tenure_days     INTEGER,           -- enrichissement : jours depuis signup (date de réf. fixe)
    segment         VARCHAR,
    loaded_at       TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.dim_product (
    product_key    INTEGER PRIMARY KEY DEFAULT nextval('warehouse.seq_dim_product'),
    product_id_src INTEGER,
    product_name   VARCHAR,
    category_id    INTEGER,
    category_name  VARCHAR,
    department     VARCHAR,
    unit_price     DECIMAL(10,2),
    cost_price     DECIMAL(10,2),
    active_flag    INTEGER,
    loaded_at      TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.dim_channel (
    channel_key  INTEGER PRIMARY KEY DEFAULT nextval('warehouse.seq_dim_channel'),
    channel_name VARCHAR UNIQUE,        -- joined as a text key by the facts
    channel_type VARCHAR
);

-- FACTS
CREATE OR REPLACE TABLE warehouse.fact_sales (
    sales_key         INTEGER PRIMARY KEY DEFAULT nextval('warehouse.seq_fact_sales'),  -- warehouse surrogate
    order_item_id_src INTEGER,              -- staging natural key (traceability)
    date_key        INTEGER,
    customer_key    INTEGER,
    product_key     INTEGER,
    channel_key     INTEGER,
    order_id        INTEGER,
    quantity        INTEGER,
    sale_unit_price DECIMAL(10,2),
    cost_unit_price DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    gross_amount    DECIMAL(10,2),
    net_amount      DECIMAL(10,2),
    cost_amount     DECIMAL(10,2),
    margin_amount   DECIMAL(10,2),
    order_status    VARCHAR,
    loaded_at       TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.fact_stock (
    stock_key       INTEGER PRIMARY KEY DEFAULT nextval('warehouse.seq_fact_stock'),  -- warehouse surrogate
    movement_id_src INTEGER,            -- staging natural key (traceability)
    date_key        INTEGER,
    product_key     INTEGER,
    qty_in          INTEGER,
    qty_out         INTEGER,
    warehouse       VARCHAR,
    loaded_at       TIMESTAMP
);

CREATE OR REPLACE TABLE warehouse.fact_budget (
    budget_id     INTEGER PRIMARY KEY,  -- clé naturelle source (pas de séquence)
    year          INTEGER,
    month_num     INTEGER,
    category_id   INTEGER,
    category_name VARCHAR,
    channel_key   INTEGER,
    budget_amount DECIMAL(10,2),
    budget_qty    INTEGER,
    loaded_at     TIMESTAMP
);
