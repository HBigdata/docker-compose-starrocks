#!/usr/bin/env sh

wait_for() {
    echo Waiting for $1 to listen on $2...
    while ! nc -z $1 $2; do echo waiting...; sleep 1s; done
}

startStarRocks() {

   node_type="$1"
   fe_leader="$2"
   fe_query_port="$3"
   fqdn=`hostname`

   if [ "$node_type" = "fe" ];then

       if [ "$fe_leader" ];then

          wait_for $fe_leader $fe_query_port

          mysql -h $fe_leader -P${fe_query_port} -uroot -e "ALTER SYSTEM ADD FOLLOWER \"${fqdn}:9010\"";

          ${StarRocks_HOME}/fe/bin/start_fe.sh --helper ${fe_leader}:9010 --host_type FQDN

       else
          ${StarRocks_HOME}/fe/bin/start_fe.sh --host_type FQDN
       fi

       #tail -f ${StarRocks_HOME}/fe/log/fe.log

   elif [ "$node_type" = "be" ];then

       wait_for $fe_leader $fe_query_port

       mysql -h ${fe_leader} -P${fe_query_port} -uroot -e "ALTER SYSTEM ADD BACKEND \"${fqdn}:9050\"";

       ${StarRocks_HOME}/be/bin/start_be.sh

       tail -f ${StarRocks_HOME}/be/log/be.log

   elif [ "$node_type" = "broker" ];then

       wait_for $fe_leader $fe_query_port

       mysql -h ${fe_leader} -P${fe_query_port} -uroot -e "ALTER SYSTEM ADD BROKER ${fqdn} \"${fqdn}:8000\"";

       ${StarRocks_HOME}/apache_hdfs_broker/bin/start_broker.sh

       tail -f ${StarRocks_HOME}/apache_hdfs_broker/log/apache_hdfs_broker.log

   fi

}

startStarRocks $@

