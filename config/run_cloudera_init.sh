#!/bin/bash

## Pasos de inicialización tomados de CDH5.4
## http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_qs_yarn_pseudo.html

#Formatear el NameNode
echo "Formatear el NameNode"
sudo -u hdfs hdfs namenode -format

#Iniciar el HDFS
echo "Iniciar el HDFS"
bash -c 'for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done'

#Crear la estructura de directorios necesarios para los procesos de Hadoop  (en el HDFS)
echo "Crear la estructura de directorios necesarios para los procesos de Hadoop  (en el HDFS)"
/usr/lib/hadoop/libexec/init-hdfs.sh

sudo -u hive hdfs dfs -mkdir       /user/hive/warehouse
sudo -u hive hdfs dfs -chmod g+w   /user/hive/warehouse
# sudo -u hdfs hdfs dfs -mkdir /hbase
# sudo -u hdfs hdfs dfs -chown hbase /hbase

#Verificar la estructura de archivos recién creada
echo "Verificar la estructura de archivos del HDFS"
sudo -u hdfs hadoop fs -ls -R /

#Inicialiazar YARN
echo "Iniciar YARN"
service hadoop-yarn-resourcemanager start
service hadoop-yarn-nodemanager start
service hadoop-mapreduce-historyserver start

# Inicializar MySQL
echo "Iniciar MySQL"
service mysql start

# Crear el metastore en mysql
echo "Crear la base de datos del Hive-metastore"
mysql -u root -e "create database metastore;" --verbose
mysql -u root -e "use metastore; source /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-1.1.0.mysql.sql;" --verbose
mysql -u root metastore < /tmp/hive-metastore-users.sql
