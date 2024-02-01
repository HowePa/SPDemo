#!/bin/bash

node_id=(1 2)
node_host=(${SP_CLICKHOUSE_HOST} ${SP_CLICKHOUSE_HOST})
node_port=(${SP_CLICKHOUSE_1_PORT} ${SP_CLICKHOUSE_2_PORT})
num_consumers=(2 4)

case "$@" in
    "create")
#### create database
        for idx in {0..1}; do
            create_db="CREATE DATABASE IF NOT EXISTS rbtest;"
            echo "$create_db" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n
        done

#### create consumer
        for idx in {0..1}; do
            for topic_id in {0..5}; do
                create_consumer="CREATE TABLE IF NOT EXISTS rbtest.consumer_rb${topic_id}
(
    id Int32,
    name String
)
ENGINE = Kafka()
SETTINGS 
kafka_broker_list = 'SASL_PLAINTEXT://sp-kafka:9092', 
kafka_topic_list = 'rb${topic_id}', 
kafka_format = 'CSV', 
kafka_row_delimiter = '\n', 
kafka_group_name = 'rbtest${topic_id}', 
kafka_client_id = 'node${node_id[$idx]}_rb${topic_id}_r0', 
kafka_num_consumers = ${num_consumers[$idx]};"
                echo "$create_consumer" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
            done
        done

#### create local
        create_local="CREATE TABLE IF NOT EXISTS rbtest.local_rb ON CLUSTER spcluster
(
    id Int32,
    name String
)
ENGINE = MergeTree
ORDER BY id;
CREATE TABLE IF NOT EXISTS rbtest.distrib_rb ON CLUSTER spcluster
(
    id Int32,
    name String
)
ENGINE = Distributed('spcluster', 'rbtest', 'local_rb', sipHash64(id));"
        echo "$create_local" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t

#### create mv
        for topic_id in {0..5}; do
            create_mv="CREATE MATERIALIZED VIEW rbtest.mv_rb${topic_id} ON CLUSTER spcluster TO rbtest.distrib_rb AS
    SELECT
    id,
    name
    FROM rbtest.consumer_rb${topic_id};"
            echo "$create_mv" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "drop")
        for idx in {0..1}; do
            drop_sql="DROP DATABASE IF EXISTS rbtest SYNC;"
            echo "$drop_sql" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "list")
        for idx in {0..1}; do
            count_sql="SELECT
'${idx}' as node, 
table, 
assignments.topic AS topics, 
length(assignments.partition_id) AS num_kafka_parts 
FROM system.kafka_consumers;"
            echo "$count_sql" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
    "count")
        for idx in {0..1}; do
            count_sql="SELECT
'${idx}' as node, 
table, 
sum(length(assignments.partition_id))
FROM system.kafka_consumers GROUP BY table;"
            echo "$count_sql" | clickhouse-client --host ${node_host[$idx]} --port ${node_port[$idx]} -n -t
        done
        ;;
esac