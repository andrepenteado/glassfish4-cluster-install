#!/bin/bash
#
#Configurações do instalador

# Path da instalação do glassfish
GLASSFISH_PATH=/SISTEMAS/glassfish4

# Nome do dominio
DOMAIN=sistemas-unesp

# Servidores [nós] remotos que executarão instâncias do glassfish
NODES=("glassfish-server01" "glassfish-server02")

# Quantidade de instâncias em cada nó remoto, que rodarão as aplicações
INSTANCES_FOR_NODE=1

# Caso os servidores [nós] tenham mais de 1 interface de rede,
# identificar os IPs externos e de conexão local entre as instâncias,
# Sendo o 1o item do servidor local
#CONNECTION_ADDR=("192.168.56.1" "192.168.56.200" "192.168.56.201")
#EXTERNAL_ADDR=("200.145.150.170" "10.0.3.15" "10.0.3.15")

# Memória para cada instância
JAVA_MX=1024m
JAVA_PERMGEN=256m

# Máximo de conexões de usuários e da aplicação com o banco de dados
MAX_CONNECTIONS=200
MAX_DB_CONNECTIONS=50

# Localização do JAR do driver JDBC e a classe XA-DataSource
JDBC_DRIVER=/SISTEMAS/instalador-cluster/postgresql-9.1-902.jdbc4.jar
DATASOURCE_CLASS=org.postgresql.xa.PGXADataSource
