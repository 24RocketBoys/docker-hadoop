# docker-hadoop

## Hadoop en modo Pseudo-distribuido

Para crear un contenedor de docker ejecuta lo siguiente:

```{bash}
docker run -ti --name hadoop-pseudo \
  -v /home/nano/tmp/data:/home/itam/data \
  -p 2122:2122 -p 2181:2181 -p 39534:39534 -p 9000:9000 \
  -p 50070:50070 -p 50010:50010 -p 50020:50020 -p 50075:50075 \
  -p 50090:50090 -p 8030:8030 -p 8031:8031 -p 8032:8032 \
  -p 8033:8033 -p 8088:8088 -p 8040:8040 -p 8042:8042 \
  -p 13562:13562 -p 47784:47784 -p 10020:10020 -p 19888:19888 \
  -p 8000:8000 -p 9999:9999 \
nanounanue/docker_hadoop
```
