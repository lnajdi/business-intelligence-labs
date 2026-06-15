-- sql/41_load_budget.sql

CREATE TABLE IF NOT EXISTS raw.sales_budget AS
    SELECT * FROM read_csv_auto('data/raw/sales_budget.csv', header=true);

TRUNCATE warehouse.fact_budget;

INSERT INTO warehouse.fact_budget
SELECT
    b.budget_id,
    b.year,
    b.month        AS month_num,
    b.category_id,
    c.category_name,
    dch.channel_key,
    b.channel      AS channel_name,
    b.budget_amount,
    b.budget_qty,
    CURRENT_TIMESTAMP AS loaded_at
FROM raw.sales_budget b
LEFT JOIN raw.categories    c   ON b.category_id = c.category_id
LEFT JOIN warehouse.dim_channel dch ON b.channel = dch.channel_name;
