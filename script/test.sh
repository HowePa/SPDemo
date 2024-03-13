#!/bin/bash

num_topics=5
node_id=(0 1)
node_host=(${SP_CLICKHOUSE_HOST} ${SP_CLICKHOUSE_HOST})
node_port=(${SP_CLICKHOUSE_1_PORT} ${SP_CLICKHOUSE_2_PORT})
num_consumers=(2 4)

case "$@" in
    "create_topic")
        for ((topic_id=0; topic_id<${num_topics}; topic_id++)); do
            docker exec -it sp-kafka /usr/bin/kafka-topics --bootstrap-server sp-kafka:19092 --create --topic rb${topic_id} --replication-factor 1 --partitions 17
        done
        docker exec -it sp-kafka /usr/bin/kafka-topics --bootstrap-server sp-kafka:19092 --list
        ;;
    "del_topic")
        for ((topic_id=0; topic_id<${num_topics}; topic_id++)); do
            docker exec -it sp-kafka /usr/bin/kafka-topics --bootstrap-server sp-kafka:19092 --delete --topic rb${topic_id}
        done
        docker exec -it sp-kafka /usr/bin/kafka-topics --bootstrap-server sp-kafka:19092 --list
        ;;
    "create")
        for idx in ${node_id[@]}; do
            create_db="CREATE DATABASE IF NOT EXISTS rbtest;"
            echo "$create_db" | $SP_CLICKHOUSE_BIN client --host ${node_host[$idx]} --port ${node_port[$idx]} -n
            topic_list="rb0"
            for ((topic_id=1; topic_id<${num_topics}; topic_id++)); do
                topic_list="${topic_list},rb${topic_id}"
            done
            create_sql="CREATE TABLE IF NOT EXISTS rbtest.consumer
(
    id Int32,
    name String
)
ENGINE = Kafka()
SETTINGS 
kafka_broker_list = 'SASL_PLAINTEXT://sp-kafka:9092', 
kafka_topic_list = '${topic_list}', 
kafka_format = 'CSV', 
kafka_row_delimiter = '\n', 
kafka_group_name = 'rbtest', 
kafka_client_id = 'node${node_id[$idx]}_rb${topic_id}_r0', 
kafka_num_consumers = ${num_consumers[$idx]};

CREATE TABLE IF NOT EXISTS rbtest.local
(
    id Int32,
    name String
)
ENGINE = MergeTree
ORDER BY id;

CREATE MATERIALIZED VIEW rbtest.mv TO rbtest.local AS
SELECT
id,
name
FROM rbtest.consumer;"
            echo "$create_sql" | $SP_CLICKHOUSE_BIN client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "drop")
        for idx in ${node_id[@]}; do
            drop_sql="DROP DATABASE IF EXISTS rbtest SYNC;"
            echo "$drop_sql" | $SP_CLICKHOUSE_BIN client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "list")
        for idx in ${node_id[@]}; do
            count_sql="SELECT
'${idx}' as node, 
table, 
assignments.topic AS topics, 
length(assignments.partition_id) AS num_kafka_parts 
FROM system.kafka_consumers;"
            echo "$count_sql" | $SP_CLICKHOUSE_BIN client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "count")
        for idx in ${node_id[@]}; do
            count_sql="SELECT
'${idx}' as node, 
table, 
sum(length(assignments.partition_id))
FROM system.kafka_consumers GROUP BY table;"
            echo "$count_sql" | $SP_CLICKHOUSE_BIN client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
esac