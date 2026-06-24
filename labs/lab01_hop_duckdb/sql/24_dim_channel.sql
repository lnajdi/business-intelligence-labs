-- sql/24_dim_channel.sql
-- channel_key n'est PAS frappée ici : DEFAULT nextval('warehouse.seq_dim_channel').
INSERT INTO warehouse.dim_channel
    (channel_name, channel_type)
SELECT
    channel                                        AS channel_name,
    CASE channel
        WHEN 'Online'  THEN 'Digital'
        WHEN 'Store'   THEN 'Physical'
        WHEN 'Partner' THEN 'Indirect'
        ELSE 'Unknown'
    END                                            AS channel_type
FROM (SELECT DISTINCT channel FROM staging.orders) t;
