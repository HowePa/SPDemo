CREATE DATABASE IF NOT EXISTS test_kafka;

CREATE TABLE IF NOT EXISTS test_kafka.src
(
    id UInt64,
    body String
)
ENGINE = Kafka
SETTINGS 
    kafka_broker_list = 'sp-kafka:19092',
    kafka_topic_list = 'test-kafka',
    kafka_group_name = 'test-kafka',
    kafka_format = 'CSV',
    format_csv_delimiter='#',
    format_csv_allow_double_quotes = 0,
    kafka_num_consumers = 2,
    kafka_skip_broken_messages = 100;

CREATE TABLE IF NOT EXISTS test_kafka.tar
(
    id UInt64,
    body String
)
ENGINE = MergeTree
ORDER BY id;

CREATE MATERIALIZED VIEW test_kafka.mv TO test_kafka.tar AS
SELECT
    id,
    body
FROM test_kafka.src;

CREATE TABLE IF NOT EXISTS test_kafka.err
(
    topic LowCardinality(String),
    key String,
    offset UInt64,
    timestamp Nullable(DateTime),
    partition UInt64,
    raw_message Nullable(String),
    error Nullable(String)
)
ENGINE = MergeTree
ORDER BY (topic, offset);

CREATE MATERIALIZED VIEW test_kafka.mv_err TO test_kafka.err AS
SELECT
    _topic,
    _key,
    _offset,
    _timestamp,
    _partition,
    _raw_message,
    _error
FROM test_kafka.src;

SHOW TABLES FROM test_kafka;
