FROM ubuntu:14.10
MAINTAINER Adolfo De Unánue Tiscareño

USER root
WORKDIR /root/

# Instalar add-apt-repository
RUN apt-get update && apt-get install -y software-properties-common

# Habilitar los repositorios de Oracle
RUN add-apt-repository -y multiverse && \
  add-apt-repository -y restricted && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && apt-get upgrade -y

# Instalar Oracle Java7
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
  apt-get install -y oracle-java7-installer oracle-java7-set-default

# Instalar paquetería
RUN apt-get install -y ssh zookeeperd lzop git rsync curl python-dev python-setuptools libcurl4-openssl-dev 

# Descargas
RUN wget -q 'http://mirror.its.dal.ca/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz'
RUN wget -c 'http://apache.webxcreen.org/hive/hive-0.14.0/apache-hive-0.14.0-bin.tar.gz'
RUN wget -c 'http://d3kbcqa49mib13.cloudfront.net/spark-1.2.0-bin-hadoop2.4.tgz'
RUN wget -c 'http://apache.webxcreen.org/pig/pig-0.14.0/pig-0.14.0.tar.gz'


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

# COnflicto de puertos
RUN sed -i "/^[^#]*UsePAM/ s/.*/#&/" /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config


# Arreglando un problema de Ubuntu con SSH en Docker: http://docs.docker.io/en/latest/examples/running_ssh_service/
RUN sed -ri 's/session[[:blank:]]+required[[:blank:]]+pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd

# Descomprimiendo y arreglando permisos
RUN tar xvfz /root/hadoop-2.6.0.tar.gz -C /opt && \
  ln -s /opt/hadoop-2.6.0 /opt/hadoop && \
  chown -R hduser:hadoop /opt/hadoop-2.6.0 && \
  mkdir /opt/hadoop-2.6.0/logs && \
  chown -R hduser:hadoop /opt/hadoop-2.6.0/logs

RUN tar xvfz /root/apache-hive-0.14.0-bin.tar.gz -C /opt && \
  ln -s /opt/apache-hive-0.14.0-bin /opt/hive && \
  chown -R hduser:hadoop /opt/apache-hive-0.14.0-bin
  
RUN tar xvfz /root/spark-1.2.0-bin-hadoop2.4.tgzz -C /opt && \
  ln -s /opt/spark-1.2.0-bin-hadoop2.4 /opt/spark && \
  chown -R hduser:hadoop /opt/spark-1.2.0-bin-hadoop2.4

RUN tar xvfz /root/pig-0.14.0.tar.gz -C /opt && \
  ln -s /opt/pig-0.14.0 /opt/pig && \
  chown -R hduser:hadoop /opt/pig-0.14.0
  

# Ajustando el ambiente de hduser
ADD config/bashrc /home/hduser/.bashrc

# Configurando Hadoop como Pseudodistribuido
ADD config/core-site.xml /tmp/hadoop-etc/core-site.xml
ADD config/yarn-site.xml /tmp/hadoop-etc/yarn-site.xml
ADD config/mapred-site.xml /tmp/hadoop-etc/mapred-site.xml
ADD config/hdfs-site.xml /tmp/hadoop-etc/hdfs-site.xml

RUN mv /tmp/hadoop-etc/* /opt/hadoop/etc/hadoop/

# SSH
EXPOSE 22

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
