CREATE DATABASE IF NOT EXISTS sptest ON CLUSTER spcluster;

-- Kafka consumer table
CREATE TABLE IF NOT EXISTS sptest.kafka_src_table ON CLUSTER spcluster
(
    `timestamp` DateTime('Asia/Shanghai'),
    `id` Int32,
    `message` String
)
ENGINE = Kafka
SETTINGS 
    kafka_broker_list = 'sp-kafka:9092', 
    kafka_topic_list = 'sptest', 
    kafka_group_name = 'sptest', 
    kafka_format = 'CSV', 
    kafka_row_delimiter = '\n', 
    format_csv_delimiter = '|', 
    kafka_skip_broken_messages = 100, 
    kafka_handle_error_mode = 'stream';

-- MergeTree table using hot_and_cold policy with cold data store to HDFS
CREATE TABLE IF NOT EXISTS sptest.kafka_table_local ON CLUSTER spcluster
(
    `timestamp` DateTime('Asia/Shanghai'),
    `id` Int32,
    `message` String
)
ENGINE = MergeTree
ORDER BY id
TTL timestamp TO VOLUME 'hot', timestamp + INTERVAL 2 HOUR TO VOLUME 'cold'
SETTINGS storage_policy = 'hot_and_cold';

-- Distributed table
CREATE TABLE IF NOT EXISTS sptest.kafka_table ON CLUSTER spcluster
(
    `timestamp` DateTime('Asia/Shanghai'),
    `id` Int32,
    `message` String
)
ENGINE = Distributed('spcluster', 'sptest', 'kafka_table_local', rand());

-- Materialized view for tranforming data
CREATE MATERIALIZED VIEW sptest.kafka_table_mv ON CLUSTER spcluster TO sptest.kafka_table AS
SELECT
    timestamp,
    id,
    message
FROM sptest.kafka_src_table;
