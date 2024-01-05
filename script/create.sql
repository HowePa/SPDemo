CREATE DATABASE IF NOT EXISTS sptest ON CLUSTER spcluster;

-- Kafka engine table for consuming streaming data
CREATE TABLE IF NOT EXISTS sptest.kafka_src_table ON CLUSTER spcluster
(
    id Int32,
    name String,
    message String
)
ENGINE = Kafka()
SETTINGS
    kafka_broker_list = 'localhost:9092',
    kafka_topic_list = 'test',
    kafka_group_name = 'group1',
    kafka_format = 'JSONEachRow';

-- MergeTree engine table with storing data in HDFS 
CREATE TABLE IF NOT EXISTS kafka_table_local ON CLUSTER spcluster
(
    id Int32,
    name String,
    message String
)
ENGINE = MergeTree()
ORDER BY (id)
SETTINGS storage_policy = 'hot_and_cold',
TTL date + INTERVAL 1 HOUR TO VOLUME 'cold';

-- Materialized view for tranforming data
CREATE MATERIALIZED VIEW consumer ON CLUSTER spcluster TO kafka_table_local AS
SELECT
    id,
    name,
    message
FROM kafka_src_table;
