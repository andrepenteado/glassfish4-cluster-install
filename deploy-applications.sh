#!/bin/bash
#
# Configura recursos e faz o deploy das aplicações da UNESP
# Autor: André Penteado
# Data: 07/08/2012


# Carregar Configurações
. ./config.sh
. ./global.sh

cp $JDBC_DRIVER $GLASSFISH_PATH/glassfish/domains/$DOMAIN/lib/

# Acesso ao banco de dados da aplicação
$ASADMIN create-jdbc-connection-pool --datasourceclassname $DATASOURCE_CLASS --maxpoolsize $MAX_DB_CONNECTIONS --isconnectvalidatereq=true --validationmethod=auto-commit --failconnection=true --leaktimeout=5 --leakreclaim=true --creationretryattempts=2 --creationretryinterval=10 --restype javax.sql.XADataSource --property user=coreuser:password=_w1Nt3r@:DatabaseName=coredb:ServerName=alphadesktop coredb-postgresql-pool
$ASADMIN create-jdbc-connection-pool --datasourceclassname $DATASOURCE_CLASS --maxpoolsize $MAX_DB_CONNECTIONS --isconnectvalidatereq=true --validationmethod=auto-commit --failconnection=true --leaktimeout=5 --leakreclaim=true --creationretryattempts=2 --creationretryinterval=10 --restype javax.sql.XADataSource --property user=contest:password=ContEst@:DatabaseName=contest:ServerName=alphadesktop contest-postgresql-pool
$ASADMIN create-jdbc-resource --target $TARGET --connectionpoolid coredb-postgresql-pool jdbc/coredb-postgresql
$ASADMIN create-jdbc-resource --target $TARGET --connectionpoolid contest-postgresql-pool jdbc/contest-postgresql

$ASADMIN stop-cluster $CLUSTER
$ASADMIN stop-domain $DOMAIN
$ASADMIN start-domain $DOMAIN
$ASADMIN start-cluster $CLUSTER

$ASADMIN ping-connection-pool coredb-postgresql-pool
$ASADMIN ping-connection-pool contest-postgresql-pool

# Configurações para o servidor
./asadmin create-custom-resource --factoryclass org.glassfish.resources.custom.factory.PrimitivesAndStringFactory --restype java.lang.String --property value="/home/andre/Projetos/config.properties" resource/configuracao

# Implantar aplicação de testes
#$ASADMIN deploy --target $CLUSTER --availabilityenabled=true --contextroot clusterjsp $CLUSTERJSP_WAR
