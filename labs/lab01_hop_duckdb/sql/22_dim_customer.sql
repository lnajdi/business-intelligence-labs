-- sql/22_dim_customer.sql
-- customer_key n'est PAS frappée ici : la colonne a un DEFAULT nextval (séquence
-- warehouse.seq_dim_customer) -> on ne l'insère pas, la base la remplit.
-- customer_id IS NOT NULL n'est PAS re-testé : staging (p01 Validate customer_id)
-- le garantit déjà (une condition = une seule couche). Ici on ne traite que le
-- métier/référentiel : customer_name non nul + déduplication sur customer_id.
-- Date de référence FIXE pour tenure_days (reproductibilité, borne haute dim_date).
INSERT INTO warehouse.dim_customer
    (customer_id_src, customer_name, email, city, region, country, country_name,
     signup_date, tenure_days, segment, loaded_at)
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date, customer_name) AS rn
    FROM staging.customers
    WHERE customer_name IS NOT NULL
)
SELECT
    customer_id                                    AS customer_id_src,
    customer_name,
    COALESCE(email, 'unknown@unknown.com')          AS email,
    CASE UPPER(TRIM(city))
        WHEN 'CASABLANCA'  THEN 'Casablanca'
        WHEN 'RABAT'       THEN 'Rabat'
        WHEN 'MARRAKECH'   THEN 'Marrakech'
        WHEN 'FES'         THEN 'Fes'
        WHEN 'FEZ'         THEN 'Fes'
        WHEN 'TANGIER'     THEN 'Tangier'
        WHEN 'TANGER'      THEN 'Tangier'
        WHEN 'AGADIR'      THEN 'Agadir'
        ELSE 'Unknown'
    END                                            AS city,
    CASE UPPER(TRIM(city))
        WHEN 'CASABLANCA'  THEN 'Grand Casablanca'
        WHEN 'RABAT'       THEN 'Rabat-Salé'
        WHEN 'MARRAKECH'   THEN 'Marrakech-Safi'
        WHEN 'FES'         THEN 'Fès-Meknès'
        WHEN 'FEZ'         THEN 'Fès-Meknès'
        WHEN 'TANGIER'     THEN 'Tanger-Tétouan'
        WHEN 'TANGER'      THEN 'Tanger-Tétouan'
        WHEN 'AGADIR'      THEN 'Souss-Massa'
        ELSE 'Unknown'
    END                                            AS region,
    country,
    CASE UPPER(TRIM(country))
        WHEN 'MA' THEN 'Morocco'
        ELSE 'Unknown'
    END                                            AS country_name,
    signup_date,
    (DATE '2026-12-31' - signup_date)              AS tenure_days,
    segment,
    CURRENT_TIMESTAMP                              AS loaded_at
FROM deduped
WHERE rn = 1;
