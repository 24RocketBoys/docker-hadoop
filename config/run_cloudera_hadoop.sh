#!/bin/bash

echo "Inicializando el SSH"
service ssh start

echo "Inicializando los servicios de HDFS"
bash -c 'for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done'

echo "Inicializando los servicios de YARN"
service hadoop-yarn-resourcemanager start
service hadoop-yarn-nodemanager start
service hadoop-mapreduce-historyserver start

echo "Inicializando Oozie"
export OOZIE_URL=http://localhost:11000/oozie
service oozie start

echo "Inicializando Spark"
service spark-master start
service spark-worker start

# echo "Inicializando HUE"
# service hue start

# echo "Inicializando Apache Solr"
# service solr-server start

echo "Inicializando Impala"
bash -c 'for x in `cd /etc/init.d ; ls impala-*` ; do sudo service $x start ; done'
service hbase-master start



echo "Presiona Ctrl+P y Ctrl+Q para mandar este proceso al background."
echo 'Usa "docker exec -i -t CONTAINER_ID /bin/zsh" para crear una nueva instancia\'
echo "Inicializa la terminal"
/bin/zsh
echo "Presiona Ctrl+C para detener la instancia."
sleep infinity
