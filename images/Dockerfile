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
