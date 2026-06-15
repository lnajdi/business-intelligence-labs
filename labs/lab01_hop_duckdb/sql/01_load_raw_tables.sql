CREATE SCHEMA IF NOT EXISTS raw;

CREATE OR REPLACE TABLE raw.customers AS
SELECT * FROM read_csv_auto('data/raw/customers.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.categories AS
SELECT * FROM read_csv_auto('data/raw/categories.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.products AS
SELECT * FROM read_csv_auto('data/raw/products.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.orders AS
SELECT * FROM read_csv_auto('data/raw/orders.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.order_items AS
SELECT * FROM read_csv_auto('data/raw/order_items.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.payments AS
SELECT * FROM read_csv_auto('data/raw/payments.csv', header=true, nullstr='');

CREATE OR REPLACE TABLE raw.stock_movements AS
SELECT * FROM read_csv_auto('data/raw/stock_movements.csv', header=true, nullstr='');
