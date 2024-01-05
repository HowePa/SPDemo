### Base Settings ###
SP_SRC_DIR=${PWD}
SP_WORKSPACE=${SP_SRC_DIR}/workspace

### ClickHouse Settings ###
SP_CLICKHOUSE_HOST=127.0.0.1
SP_CLICKHOUSE_PORT=9000

### Kafka Settings ###

### HDFS Settings ###

### Zookeeper Settings ###


export SP_SRC_DIR
export SP_WORKSPACE
mkdir -p ${SP_WORKSPACE}
export SP_CLICKHOUSE_HOST
export SP_CLICKHOUSE_PORT