## Version 0.2
FROM nanounanue/docker-base
MAINTAINER Adolfo De Unánue Tiscareño

ENV REFRESHED_AT 2015-04-28
ENV DEBIAN-FRONTEND noninteractive

USER root

RUN apt-get install -y --no-install-recommends ssh lzop libkrb5-dev libmysqlclient-dev libssl-dev libsasl2-dev  libsasl2-modules-gssapi-mit libsqlite3-dev libtidy-0.99-0 libldap2-dev

RUN pip install allpairs pytest pytest-xdist paramiko texttable prettytable sqlparse psutil==0.7.1 pywebhdfs gitpython jenkinsapi


## Descargando el paquete de configuración de Cloudera
RUN wget -P /tmp -c http://archive.cloudera.com/cdh5/one-click-install/trusty/amd64/cdh5-repository_1.0_all.deb

## Instalando Hadoop de modo Pseudo Distribuido
RUN dpkg -i /tmp/cdh5-repository_1.0_all.deb \
&& apt-get update \
&& apt-get -y install hadoop-conf-pseudo

## Instalamos otros componentes del ecosistema
RUN apt-get -y install hive pig spark-core spark-master spark-worker spark-history-server spark-python flume-ng sqoop hive-webhcat-server hive-hcatalog hive-server2 hbase hbase-thrift hbase-master

## Por último instalamos Oozie e Impala
RUN apt-get -y install oozie oozie-client impala impala-server impala-state-store impala-catalog impala-shell

## Preparamos el HDFS
ADD config/run_cloudera_init.sh /tmp/run_cloudera_init.sh
RUN chmod +x /tmp/run_cloudera_init.sh; sync  \
&& /tmp/run_cloudera_init.sh

## Instalando HUE
WORKDIR /opt

RUN git clone https://github.com/cloudera/hue.git

WORKDIR /opt/hue

RUN make apps && rm -Rf /root/.m2
RUN useradd hue -r && chown hue:hue /opt/hue/desktop && chown hue:hue /opt/hue/desktop/desktop.db
RUN sed -i 's/secret_key=/secret_key=_S@s+D=h;B,s$C%k#H!dMjPmEsSaJR/g' /opt/hue/desktop/conf/pseudo-distributed.ini  # Crear la llave de HUE



## Arreglando el SSH
## Conflicto de puertos entre la máquina local y el docker para el puerto del SSH
RUN sed -i "/^[^#]*UsePAM/ s/.*/#&/" /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/ssh_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config

## SSH
EXPOSE 2122

## NameNode (HDFS)
EXPOSE 9000 50070

## DataNode (HDFS)
EXPOSE 50010 50020 50075

## SecondaryNameNode (HDFS)
EXPOSE 50090

## ResourceManager (YARN)
EXPOSE 8030 8031 8032 8033 8088

## Hadoop User Experience (HUE)
EXPOSE 8000 9999

## NodeManager (YARN)
EXPOSE 8040 8042 13562 47784

## JobHistoryServer
EXPOSE 10020 19888

WORKDIR /home/itam



## Inicializar los servicios
ADD config/run_cloudera_hadoop.sh /usr/bin/run_cloudera_hadoop.sh
RUN chmod +x /usr/bin/run_cloudera_hadoop.sh
CMD ["run_cloudera_hadoop.sh"]
