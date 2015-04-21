## Version 0.1
FROM nanounanue/docker-base
MAINTAINER Adolfo De Unánue Tiscareño

VOLUME /home/itam/tmp

ENV REFRESHED_AT 2015-04-21
ENV DEBIAN-FRONTEND noninteractive

USER root
WORKDIR /root/

# Instalar paquetería
RUN apt-get install -y ssh zookeeperd lzop

COPY apache-hive-0.14.0-bin.tar.gz  /home/itam/tmp/
COPY hadoop-2.6.0.tar.gz /home/itam/tmp/
COPY pig-0.14.0.tar.gz /home/itam/tmp/

# Descargas
#RUN wget -P /home/itam/tmp -c 'http://mirror.its.dal.ca/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz'
#RUN wget -P /home/itam/tmp -c 'http://apache.webxcreen.org/hive/hive-0.14.0/apache-hive-0.14.0-bin.tar.gz'
#RUN wget -P /home/itam/tmp -c 'http://d3kbcqa49mib13.cloudfront.net/spark-1.2.0-bin-hadoop2.4.tgz'
#RUN wget -P /home/itam/tmp -c 'http://apache.webxcreen.org/pig/pig-0.14.0/pig-0.14.0.tar.gz'
#RUN wget -P /home/itam/tmp -c 'http://downloads.typesafe.com/scala/2.11.6/scala-2.11.6.tgz'

# Agregando usuarios y grupos de acceso
RUN addgroup hadoop && adduser --ingroup hadoop hduser
RUN usermod -a -G hadoop zookeeper

# Le ponemos password
RUN echo 'hduser:hduser' | chpasswd

# Setup SSH keys for Hadoop
RUN su -l -c 'ssh-keygen -t rsa -f /home/hduser/.ssh/id_rsa -P ""' hduser && \
  cat /home/hduser/.ssh/id_rsa.pub | su -l -c 'tee -a /home/hduser/.ssh/authorized_keys' hduser
ADD config/ssh-config /home/hduser/.ssh/config
RUN chmod 600 /home/hduser/.ssh/config

# Conflicto de puertos entre la máquina local y el docker para el puerto del SSH
RUN sed -i "/^[^#]*UsePAM/ s/.*/#&/" /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/ssh_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config


# Descomprimiendo y arreglando permisos
RUN tar xvfz /home/itam/tmp/hadoop-2.6.0.tar.gz -C /srv && \
  ln -s /srv/hadoop-2.6.0 /srv/hadoop && \
  chown -R hduser:hadoop /srv/hadoop-2.6.0 && \
  mkdir /srv/hadoop-2.6.0/logs && \
  chown -R hduser:hadoop /srv/hadoop-2.6.0/logs

RUN tar xvfz /home/itam/tmp/apache-hive-0.14.0-bin.tar.gz -C /srv && \
 ln -s /srv/apache-hive-0.14.0-bin /srv/hive && \
 chown -R hduser:hadoop /srv/apache-hive-0.14.0-bin

RUN tar xvfz /home/itam/tmp/pig-0.14.0.tar.gz -C /srv && \
 ln -s /srv/pig-0.14.0 /srv/pig && \
 chown -R hduser:hadoop /srv/pig-0.14.0

# Ajustando el ambiente de hduser
ADD config/bashrc /home/hduser/.bashrc
RUN chown -R hduser:hadoop /home/hduser/.bashrc
RUN mkdir -p /home/hduser/hdfs-data/namenode /home/hduser/hdfs-data/datanode
RUN chown -R hduser:hadoop /home/hduser/hdfs-data

# Formateamos el namenode
RUN su -l -c 'hdfs namenode -format -nonInteractive' hduser


# Configurando Hadoop como Pseudodistribuido
ADD config/core-site.xml /tmp/hadoop-etc/core-site.xml
ADD config/yarn-site.xml /tmp/hadoop-etc/yarn-site.xml
ADD config/mapred-site.xml /tmp/hadoop-etc/mapred-site.xml
ADD config/hdfs-site.xml /tmp/hadoop-etc/hdfs-site.xml

RUN mv /tmp/hadoop-etc/* /srv/hadoop/etc/hadoop/

## Arreglar start-dfs.sh
ADD config/dfs.sed /home/itam/tmp/
RUN sed --file /home/itam/tmp/dfs.sed  --in-place /srv/hadoop/sbin/start-dfs.sh

# SSH
EXPOSE 2122

# QuorumPeerMain (Zookeeper)
EXPOSE 2181 39534

# NameNode (HDFS)
EXPOSE 9000 50070

# DataNode (HDFS)
EXPOSE 50010 50020 50075

# SecondaryNameNode (HDFS)
EXPOSE 50090

# ResourceManager (YARN)
EXPOSE 8030 8031 8032 8033 8088

# NodeManager (YARN)
EXPOSE 8040 8042 13562 47784

# JobHistoryServer
EXPOSE 10020 19888

# Create start script
ADD config/run-hadoop.sh /root/run-hadoop.sh
RUN chmod +x /root/run-hadoop.sh

CMD ["/root/run-hadoop.sh"]
