-- Appelé par sql/50_initial_full_load.sql uniquement.
-- Dans le chemin CLI direct, sql/01_load_raw_tables.sql
-- inclut déjà CREATE SCHEMA IF NOT EXISTS raw.
CREATE SCHEMA IF NOT EXISTS raw;
