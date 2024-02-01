# Kerberized Kafka

## Prepare

1. 安装依赖环境 `python -m pip install -r requirements.txt`
2. 依照`env.sh.sample`创建`env.sh`并加载
3. 本地要安装`clickhouse-client`

## Running

```bash
### Stage 1: 启动测试环境
./script/env_up

### Stage 2: 创建引擎表
./script/db_create

### Stage 3: 生产数据
./script/producer_rand --process 8
```

## Check Kafka Assignor

```bash
# 建表
./script/tesh.sh create
# 统计
./script/tesh.sh list
./script/tesh.sh count
# 回收
./script/tesh.sh drop
```

## Structure

1. `./docker/docker-compose.yml`: 测试环境
2. `./docker/conf`: 待测clickhouse配置
3. `./script/create.sql`: 测试数据库创建语句，按需修改
4. `./script/producer_rand`: 随机Kafka Producer，若需修改数据格式，参考`data_gen`函数
