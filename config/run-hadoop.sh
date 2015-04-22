#!/bin/bash

set -x

# Agregamos la llave pública a las llaves autorizadas
echo $AUTHORIZED_SSH_PUBLIC_KEY >> /home/hduser/.ssh/authorized_keys
chown -R hduser:hadoop /home/hduser/.ssh/authorized_keys
#chown -R hduser:hadoop /home/hduser/.ssh/config

# Formateamos el namenode
#su -l -c 'hdfs namenode -format -nonInteractive' hduser

# Iniciamos el servicio de SSH
service ssh start

# Iniciamos el ZooKeeper
service zookeeper start

# Limpiamos los logs de Hadoop
rm -fr /srv/hadoop/logs/*

# Levantamos YARN
su -l -c 'start-yarn.sh' hduser

# Levantamos HDFS
su -l -c 'start-dfs.sh' hduser

# Levantamos el JobHistory
su -l -c '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR' hduser

sleep 1

# Mostramos los logs a pantalla
tail -n 1000 -f /srv/hadoop/logs/*.log
