DROP VIEW IF EXISTS sptest.kafka_table_mv ON CLUSTER spcluster;
DROP TABLE IF EXISTS sptest.kafka_table ON CLUSTER spcluster;
DROP TABLE IF EXISTS sptest.kafka_table_local ON CLUSTER spcluster;
DROP TABLE IF EXISTS sptest.kafka_src_table ON CLUSTER spcluster;
DROP DATABASE IF EXISTS sptest ON CLUSTER spcluster;