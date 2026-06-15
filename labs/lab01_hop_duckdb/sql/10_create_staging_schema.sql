-- sql/10_create_staging_schema.sql

CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE TABLE staging.customers (
    customer_id   INTEGER PRIMARY KEY,
    customer_name VARCHAR NOT NULL,
    email         VARCHAR,
    city          VARCHAR,
    country       VARCHAR,
    signup_date   DATE,
    segment       VARCHAR
);

CREATE OR REPLACE TABLE staging.products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR NOT NULL,
    category_id   INTEGER,
    category_name VARCHAR,
    department    VARCHAR,
    unit_price    DECIMAL(10,2),
    cost_price    DECIMAL(10,2),
    active_flag   INTEGER
);

CREATE OR REPLACE TABLE staging.orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL,
    order_date    DATE NOT NULL,
    channel       VARCHAR,
    order_status  VARCHAR,
    city          VARCHAR
);

CREATE OR REPLACE TABLE staging.order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL,
    product_id      INTEGER NOT NULL,
    quantity        INTEGER,
    unit_price      DECIMAL(10,2),
    discount_amount DECIMAL(10,2)
);

CREATE OR REPLACE TABLE staging.payments (
    payment_id      INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL,
    payment_date    DATE,
    payment_method  VARCHAR,
    payment_status  VARCHAR,
    amount          DECIMAL(10,2)
);

CREATE OR REPLACE TABLE staging.stock_movements (
    movement_id    INTEGER PRIMARY KEY,
    product_id     INTEGER NOT NULL,
    movement_date  DATE,
    movement_type  VARCHAR,
    quantity       INTEGER,
    warehouse      VARCHAR
);
