#!/bin/bash
#
# Criar e configurar dominio sistemas-unesp
# para os sistemas institucionais e locais
# no servidor de aplicação GlassFish - SEM CLUSTER
#
# Criação: 27/FEV/2013
# Autor: André Penteado


#=========================== CONFIG.SH ===========================
#               Arquivo com parametros de configuração
#=================================================================

# Arquivos JARs, WARs e certificados a serem usados na nova instalação
FOLDER_FILES=/SISTEMAS/bin/arquivos-nova-instalacao
JDBC_POSTGRESQL=$FOLDER_FILES/postgresql-9.2-1002.jdbc4.jar
LOG_FORMATTER=$FOLDER_FILES/logFormatter.jar
LOG_CONFIG=$FOLDER_FILES/logging.properties
WFU_CERT=$FOLDER_FILES/ldapserver.pem
NETMANAGER_JKS=/SISTEMAS/bin/netmanager.jks
PROPERTIES_APP=/SISTEMAS/config.properties

# Outras variaveis
GLASSFISH_PATH=/SISTEMAS/glassfish-4.1
USER=glassfish
ASADMIN=$GLASSFISH_PATH/bin/asadmin
DOMAIN=sistemas-unesp
INIT=`date "+%Hh%Mm"`
PERM_SIZE=2048m
MEMORY_SIZE=13312m
MAX_WEB_CONN=800
MAX_DB_CONN=300


#==================== INSTALL-DOMAIN.SH ========================
#                    Instalador do dominio
#===============================================================
# Baixar e descompactar
#wget http://download.java.net/glassfish/4.1/release/glassfish-4.1.zip
unzip glassfish-4.1.zip
mv glassfish4 $GLASSFISH_PATH

# Criar e configurar dominio
$ASADMIN delete-domain domain1
$ASADMIN delete-domain $DOMAIN
$ASADMIN create-domain $DOMAIN
$ASADMIN start-domain $DOMAIN
$ASADMIN enable-secure-admin
$ASADMIN login
$ASADMIN stop-domain $DOMAIN

# Copiar arquivos necessários
cp $JDBC_POSTGRESQL $LOG_FORMATTER $GLASSFISH_PATH/glassfish/domains/$DOMAIN/lib/ext
cp -f $LOG_CONFIG $GLASSFISH_PATH/glassfish/domains/$DOMAIN/config

# Iniciar dominio com novas configurações
$ASADMIN start-domain $DOMAIN
$ASADMIN version --verbose

# Setando parametros para a JVM
$ASADMIN delete-jvm-options -- -client
$ASADMIN create-jvm-options -- -server
$ASADMIN delete-jvm-options -- -Xmx512m
$ASADMIN create-jvm-options -- -Xmx$MEMORY_SIZE
$ASADMIN delete-jvm-options -- "-XX\:MaxPermSize=192m"
$ASADMIN create-jvm-options -- "-XX\:MaxPermSize=$PERM_SIZE"
$ASADMIN create-jvm-options -Dproduct.name=""
$ASADMIN create-jvm-options -Duser.language=pt
$ASADMIN create-jvm-options -Duser.country=BR
$ASADMIN create-jvm-options -Duser.timezone=America/Sao_Paulo
$ASADMIN set server.network-config.protocols.protocol.http-listener-1.http.xpowered-by=false
$ASADMIN set server.network-config.protocols.protocol.http-listener-2.http.xpowered-by=false
$ASADMIN set server.network-config.protocols.protocol.admin-listener.http.xpowered-by=false

# Connector com apache
$ASADMIN create-network-listener --listenerport 8009 --protocol http-listener-1 --jkenabled true jkconnector-listener
$ASADMIN set configs.config.server-config.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size=$MAX_WEB_CONN
$ASADMIN set configs.config.server-config.network-config.network-listeners.network-listener.http-listener-1.enabled=false
$ASADMIN set configs.config.server-config.network-config.network-listeners.network-listener.http-listener-2.enabled=false

# Configurações para o servidor
$ASADMIN create-custom-resource --factoryclass org.glassfish.resources.custom.factory.PrimitivesAndStringFactory --restype java.lang.String --property value="$PROPERTIES_APP" resource/configuracao


#======================== DEPLOY-APP-<nome-servidor>.SH ==========================
#              Faz deploy das aplicações específicas deste servidor
#=================================================================================

# CoreDB @ Master
$ASADMIN create-jdbc-connection-pool --datasourceclassname org.postgresql.xa.PGXADataSource --maxpoolsize $MAX_DB_CONN --isconnectvalidatereq=true --validationmethod=auto-commit --failconnection=true --leaktimeout=5 --leakreclaim=true --creationretryattempts=2 --creationretryinterval=10 --restype javax.sql.XADataSource --property user=coreuser:password=_w1Nt3r@:DatabaseName=coredb:ServerName=master coredb-postgresql-pool
$ASADMIN create-jdbc-resource --connectionpoolid coredb-postgresql-pool jdbc/coredb-postgresql

# eConcurso @ db.bauru.unesp.br
$ASADMIN create-jdbc-connection-pool --datasourceclassname org.postgresql.xa.PGXADataSource --maxpoolsize 50 --isconnectvalidatereq=true --validationmethod=auto-commit --failconnection=true --leaktimeout=5 --leakreclaim=true --creationretryattempts=2 --creationretryinterval=10 --restype javax.sql.XADataSource --property user=econcurso:password=z5Lc31wH:DatabaseName=econcurso:ServerName=db.bauru.unesp.br econcurso-pool
$ASADMIN create-jdbc-resource --connectionpoolid econcurso-pool jdbc/econcurso

#Conexão com LDAP
#$ASADMIN create-custom-resource --factoryclass com.sun.jndi.ldap.LdapCtxFactory --restype javax.naming.directory.Directory --property java.naming.security.authentication=simple:java.naming.security.principal='cn\=admin,dc\=unesp,dc\=br':java.naming.security.credentials=pelicula:URL='ldap\://ldap.bauru.unesp.br\:389/dc\=unesp,dc\=br' ldap/central

# Instalar certificados WFU e JKSs e PEMs
echo -n | openssl s_client -connect wifildap.reitoria.unesp.br:636 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $WFU_CERT
echo "=====> As 4 [quatro] próximas senhas são dos certificados do SO [2] e Glassfish [2]. A default é 'changeit'"
keytool -import -trustcacerts -alias wifildap-reitoria -file $WFU_CERT -keystore /etc/ssl/certs/java/cacerts
keytool -import -trustcacerts -alias wifildap-reitoria -file $WFU_CERT -keystore /etc/ssl/certs/java/jssecacerts
keytool -import -trustcacerts -alias wifildap-reitoria -file $WFU_CERT -keystore $GLASSFISH_PATH/glassfish/domains/$DOMAIN/config/cacerts
keytool -import -trustcacerts -alias wifildap-reitoria -file $WFU_CERT -keystore $GLASSFISH_PATH/glassfish/domains/$DOMAIN/config/cacerts.jks
echo "=====> Senha do certificado netmanager de alias 'mykey'. Senha em branco, tecle [enter]"
keytool -export -alias mykey -file $FOLDER_FILES/netmanager.pem -keystore netmanager.jks
echo "=====> As 4 [quatro] próximas senhas são dos certificados do SO [2] e do Glassfish [2]. A default é 'changeit'"
keytool -import -trustcacerts -alias mykey -file $FOLDER_FILES/netmanager.pem -keystore /etc/ssl/certs/java/cacerts
keytool -import -trustcacerts -alias mykey -file $FOLDER_FILES/netmanager.pem -keystore /etc/ssl/certs/java/jssecacerts
keytool -import -trustcacerts -alias mykey -file $FOLDER_FILES/netmanager.pem -keystore cacerts
keytool -import -trustcacerts -alias mykey -file $FOLDER_FILES/netmanager.pem -keystore cacerts.jks

# Fazer auto-deploy dos wars copiados
#cp $FOLDER_FILES/*war $GLASSFISH_PATH/glassfish/domains/$DOMAIN/autodeploy

#==================== FINALIZAÇÃO ======================

# Carregar todas novas configurações
$ASADMIN stop-domain $DOMAIN
chown -R $USER:nogroup $GLASSFISH_PATH
#su -s /bin/sh -c "$ASADMIN start-domain $DOMAIN" $USER

echo "\n\nFIM DE EXECUÇÃO: Inicio: $INIT - Fim: `date \"+%Hh%Mm\"`\n\n"

tail -f $GLASSFISH_PATH/glassfish/domains/$DOMAIN/logs/server.log
