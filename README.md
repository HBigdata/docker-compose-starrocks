[TOC]
## 一、概述
StarRocks是一个开源的分布式OLAP（在线分析处理）数据库，旨在提供高性能、低延迟的数据分析和查询能力。它最初由中国的猎豹移动公司（Cheetah Mobile）开发，并于2016年开源。

StarRocks主要特点和功能包括：

- **列式存储**：StarRocks使用列式存储，将数据按列存储在磁盘上，以提高数据的压缩率和查询性能。列式存储有助于减少I/O开销和提高数据扫描效率。

- **分布式架构**：StarRocks基于分布式架构设计，可以水平扩展以处理大规模数据集。它支持数据分片和分布式计算，可以将数据和计算任务分布在多个节点上并行处理。

- **多维数据模型**：StarRocks支持多维数据模型，适用于OLAP分析和查询。它提供了维度模型、星型模型和雪花模型等，支持多维查询、聚合和切片切块操作。

- **实时数据同步**：StarRocks支持实时数据同步，可以通过接口、Kafka等方式实时加载数据，并保持数据的一致性和准确性。

- **高性能查询引擎**：StarRocks内置了一个高性能的查询引擎，支持复杂的SQL查询操作。它具有快速的查询速度和低延迟，并提供了聚合、排序、分组和连接等常见的查询操作。

- **高可用性和容错性**：StarRocks具有高可用性和容错性，支持数据的备份和故障恢复。它可以自动处理节点故障和数据冗余，保证数据的可靠性和可用性。

总的来说，StarRocks是一个面向OLAP场景的高性能分布式数据库，通过列式存储、多维数据模型和高性能查询引擎等特性，提供快速、可扩展的数据分析和查询能力。它广泛应用于大数据分析、实时报表、数据仪表盘等场景。

![在这里插入图片描述](https://img-blog.csdnimg.cn/cda0c214ac7b49598d7ef262fd272623.png)
想了解更多关于 StarRocks 可阅读我以下几篇文章：
- [大数据Hadoop之——DorisDB介绍与环境部署（StarRocks）](https://www.cnblogs.com/liugp/p/16513501.html)
- [大数据Hadoop之——DorisDB核心概念介绍与简单使用（StarRocks）](https://www.cnblogs.com/liugp/p/16515271.html)

从 3.0 版本开始，StarRocks 支持新的共享数据架构，可以提供更好的可扩展性和更低的成本。
![在这里插入图片描述](https://img-blog.csdnimg.cn/224d80b5138b454cba1458c23e44345f.png)

## 二、前期准备
### 1）部署 docker
```bash
# 安装yum-config-manager配置工具
yum -y install yum-utils

# 建议使用阿里云yum源：（推荐）
#yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装docker-ce版本
yum install -y docker-ce
# 启动并开机启动
systemctl enable --now docker
docker --version
```
### 2）部署 docker-compose
```bash
curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
docker-compose --version
```
## 三、创建网络

```bash
# 创建，注意不能使用hadoop_network，要不然启动hs2服务的时候会有问题！！！
docker network create hadoop-network

# 查看
docker network ls
```
## 四、StarRocks 编排部署
### 1）下载 StarRocks 部署包

```bash
wget https://releases.starrocks.io/starrocks/StarRocks-3.0.1.tar.gz
```
### 2）配置
- `conf/fe.conf`

```bash
LOG_DIR = /opt/apache/StarRocks/fe/log
DATE = "$(date +%Y%m%d-%H%M%S)"

# 修改元数据目录。
meta_dir = /opt/apache/StarRocks/fe/meta
# 在数据库运维中，如果用 IP 作为节点的唯一标识，会出现因为 IP 变动而导致服务不可用的问题。在 2.4 版本中，支持了 Fully qualified domain name（FQDN）。您可以用域名或结合主机名与端口的方式作为 FE 或 BE 节点的唯一标识，有效避免因 IP 变更导致无法访问的问题。因为容器ip是变动的，所以这里不启用priority_networks。
# priority_networks = 192.168.0.0/24
# 添加 Java 目录
JAVA_HOME = /opt/apache/jdk1.8.0_212
# 修改JVM内存，默认是8G，根据自己机器自定义，默认是-Xmx8192m，这里我修改成Xmx512m，这里有两段配置，jdk 9+使用JAVA_OPTS_FOR_JDK_9
JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -Xmx512m -XX:+UseMembar -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -Xloggc:$STARROCKS_HOME/log/fe.gc.log.$DATE"

# For jdk 9+, this JAVA_OPTS will be used as default JVM options
JAVA_OPTS_FOR_JDK_9="-Dlog4j2.formatMsgNoLookups=true -Xmx512m -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:+CMSClassUnloadingEnabled -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -Xlog:gc*:$STARROCKS_HOME/log/fe.gc.log.$DATE:time"

sys_log_level = INFO
http_port = 8030
rpc_port = 9020
query_port = 9030
edit_log_port = 9010
# 是否开启 MySQL 服务器的异步 I/O 选项。
mysql_service_nio_enabled = true
```
- `conf/be.conf`

```bash
sys_log_level = INFO
sys_log_dir = /opt/apache/StarRocks/be/log
be_port = 9060
be_http_port = 8040
heartbeat_service_port = 9050
brpc_port = 8060
# 存储路径
storage_root_path = /opt/apache/StarRocks/be/storage
```
- `conf/apache_hdfs_broker.conf`

> 通过 Broker，StarRocks 可读取对应数据源（如HDFS、S3）上的数据，利用自身的计算资源对数据进行预处理和导入。除此之外，Broker 也被应用于数据导出，备份恢复等功能。
```bash
broker_ipc_port=8000
client_expire_seconds=300
```
### 3）启动脚本 bootstrap.sh

```bash
version: '3'
services:
  starrocks-fe-1:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-1
    hostname: starrocks-fe-1
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-fe-2:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-2
    hostname: starrocks-fe-2
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-fe-3:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-3
    hostname: starrocks-fe-3
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-be:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    restart: always
    privileged: true
    deploy:
      replicas: 3
    env_file:
      - .env
    volumes:
      - ./conf/be.conf:${StarRocks_HOME}/be/conf/be.conf
    ports:
      - "${StarRocks_BE_HTTP_PORT}"
    expose:
      - "${StarRocks_BE_PORT}"
      - "${StarRocks_BE_HEARTBEAT_SERVICE_PORT}"
      - "${StarRocks_BE_BRPC_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh be starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_BE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 3
  starrocks-apache_hdfs_broker:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    restart: always
    privileged: true
    deploy:
      replicas: 3
    env_file:
      - .env
    volumes:
      - ./conf/apache_hdfs_broker.conf:${StarRocks_HOME}/apache_hdfs_broker/conf/apache_hdfs_broker.conf
    expose:
      - "${StarRocks_BROKER_IPC_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh broker starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_BROKER_IPC_PORT} || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 3

# 连接外部网络
networks:
  hadoop-network:
    external: true
```
### 4）构建镜像 Dockerfile
```bash
FROM registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/centos-jdk:7.7.1908

# install client mysql
RUN yum -y install mysql

# 添加 StarRocks 包
ENV StarRocks_VERSION 3.0.1
RUN mkdir /opt/apache/StarRocks-${StarRocks_VERSION}
ADD StarRocks-${StarRocks_VERSION}.tar.gz /opt/apache/
ENV StarRocks_HOME /opt/apache/StarRocks
RUN ln -s /opt/apache/StarRocks-${StarRocks_VERSION} $StarRocks_HOME

# 创建存储目录
RUN mkdir /opt/apache/StarRocks/fe/meta
RUN mkdir /opt/apache/StarRocks/be/storage

# copy bootstrap.sh
COPY bootstrap.sh /opt/apache/
RUN chmod +x /opt/apache/bootstrap.sh

RUN chown -R hadoop:hadoop /opt/apache

WORKDIR $StarRocks_HOME
```
开始构建镜像

```bash
docker build -t registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1 . --no-cache

# 为了方便小伙伴下载即可使用，我这里将镜像文件推送到阿里云的镜像仓库
docker push registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1

### 参数解释
# -t：指定镜像名称
# . ：当前目录Dockerfile
# -f：指定Dockerfile路径
#  --no-cache：不缓存
```
### 5）编排 docker-compose.yaml

```yaml
version: '3'
services:
  starrocks-fe-1:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-1
    hostname: starrocks-fe-1
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-fe-2:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-2
    hostname: starrocks-fe-2
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-fe-3:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    container_name: starrocks-fe-3
    hostname: starrocks-fe-3
    restart: always
    privileged: true
    env_file:
      - .env
    volumes:
      - ./conf/fe.conf:${StarRocks_HOME}/fe/conf/fe.conf
    ports:
      - "${StarRocks_FE_HTTP_PORT}"
    expose:
      - "${StarRocks_FE_RPC_PORT}"
      - "${StarRocks_FE_QUERY_PORT}"
      - "${StarRocks_FE_EDIT_LOG_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh fe starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_FE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 20s
      retries: 3
  starrocks-be:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    restart: always
    privileged: true
    deploy:
      replicas: 3
    env_file:
      - .env
    volumes:
      - ./conf/be.conf:${StarRocks_HOME}/be/conf/be.conf
    ports:
      - "${StarRocks_BE_HTTP_PORT}"
    expose:
      - "${StarRocks_BE_PORT}"
      - "${StarRocks_BE_HEARTBEAT_SERVICE_PORT}"
      - "${StarRocks_BE_BRPC_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh be starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_BE_HTTP_PORT} || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 3
  starrocks-apache_hdfs_broker:
    image: registry.cn-hangzhou.aliyuncs.com/bigdata_cloudnative/starrocks:3.0.1
    user: "hadoop:hadoop"
    restart: always
    privileged: true
    deploy:
      replicas: 3
    env_file:
      - .env
    volumes:
      - ./conf/apache_hdfs_broker.conf:${StarRocks_HOME}/apache_hdfs_broker/conf/apache_hdfs_broker.conf
    expose:
      - "${StarRocks_BROKER_IPC_PORT}"
    command: ["sh","-c","/opt/apache/bootstrap.sh broker starrocks-fe-1 ${StarRocks_FE_QUERY_PORT}"]
    networks:
      - hadoop-network
    healthcheck:
      test: ["CMD-SHELL", "netstat -tnlp|grep :${StarRocks_BROKER_IPC_PORT} || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 3

# 连接外部网络
networks:
  hadoop-network:
    external: true
```
`.env` 文件内容：

```bash
StarRocks_HOME=/opt/apache/StarRocks
StarRocks_FE_HTTP_PORT=8030
StarRocks_FE_RPC_PORT=9020
StarRocks_FE_QUERY_PORT=9030
StarRocks_FE_EDIT_LOG_PORT=9010
StarRocks_BE_HTTP_PORT=8040
StarRocks_BE_PORT=9060
StarRocks_BE_HEARTBEAT_SERVICE_PORT=9050
StarRocks_BE_BRPC_PORT=8060
StarRocks_BROKER_IPC_PORT=8000
```

### 6）开始部署

```bash
# p=sr：项目名，默认项目名是当前目录名称
docker-compose -f docker-compose.yaml -p=sr up -d

# 查看
docker-compose -f docker-compose.yaml -p=sr ps

# 卸载
docker-compose -f docker-compose.yaml -p=sr down
```
![在这里插入图片描述](https://img-blog.csdnimg.cn/e4cc8fe4cc304460a706baa7f818404b.png)
## 五、简单测试验证

```bash
# 查看FE http 对外端口
docker-compose -f docker-compose.yaml -p=sr ps
```

web：`http://ip:port`

![在这里插入图片描述](https://img-blog.csdnimg.cn/14d7dff75ebe4ef3818144e122d9d9da.png)
## 六、常用的 StarRocks 客户端命令
### 1）服务启停

```bash
### 1、第一个 FE 服务启停
${StarRocks_HOME}/fe/bin/start_fe.sh --host_type FQDN

### 2、添加FE节点
# 添加节点
mysql -h ${fe_leader} -P9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER \"${fqdn}:9010\"";
# 服务启动
${StarRocks_HOME}/fe/bin/start_fe.sh --helper ${fe_leader}:9010 --host_type FQDN

### 3、添加BE节点
# 添加节点
mysql -h ${fe_leader} -P9030 -uroot -e "ALTER SYSTEM ADD BACKEND \"${fqdn}:9050\"";
# 服务启动
${StarRocks_HOME}/be/bin/start_be.sh

#### 4、添加 broker 节点
# 添加节点
mysql -h ${fe_leader} -P9030 -uroot -e "ALTER SYSTEM ADD BROKER ${broker_name} \"${fqdn}:8000\"";
# 服务启动
${StarRocks_HOME}/apache_hdfs_broker/bin/start_broker.sh

### 5、服务停止
${StarRocks_HOME}/fe/bin/stop_fe.sh
${StarRocks_HOME}/be/bin/stop_be.sh
${StarRocks_HOME}/apache_hdfs_broker/bin/stop_broker.sh
```
### 2、查看节点状态

```bash
mysql -h ${FE} -P9030 -uroot
# 查看 FE
SHOW PROC '/frontends'\G
# 查看 BE
SHOW PROC "/backends"\G
# 查看 broker
SHOW PROC "/brokers"\G
```
到此 通过 docker-compose 快速部署 StarRocks 保姆级教程就结束了，后续会持续更新相关技术类文章，有任何疑问欢迎关注我公众号 **`大数据与云原生技术分享`** 加群交流或私信沟通，如本篇文章对您有所帮助，麻烦帮忙一键三连（**点赞、转发、收藏**）~

![](https://img2023.cnblogs.com/blog/1601821/202306/1601821-20230612215809135-427251393.png)
