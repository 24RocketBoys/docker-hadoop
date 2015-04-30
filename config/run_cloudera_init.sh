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
echo "Step 3 - Create the directories needed for Hadoop processes"
/usr/lib/hadoop/libexec/init-hdfs.sh

sudo -u hive hdfs dfs -mkdir       /user/hive/warehouse
sudo -u hive hdfs dfs -chmod g+w   /user/hive/warehouse
# sudo -u hdfs hdfs dfs -mkdir /hbase
# sudo -u hdfs hdfs dfs -chown hbase /hbase

#Verificar la estructura de archivos recién creada
echo "Step 4: Verify the HDFS File Structure"
sudo -u hdfs hadoop fs -ls -R /

#Inicialiazar YARN
echo "Iniciar YARN"
service hadoop-yarn-resourcemanager start
service hadoop-yarn-nodemanager start
service hadoop-mapreduce-historyserver start


echo "Configurar Oozie"
update-alternatives --set oozie-tomcat-conf /etc/oozie/tomcat-conf.http
oozie-setup sharelib create -fs hdfs://localhost -locallib /usr/lib/oozie/oozie-sharelib-yarn
sudo -u hdfs hadoop fs -chown oozie:oozie /user/oozie
oozie-setup db create -run
