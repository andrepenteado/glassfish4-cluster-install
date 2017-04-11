#!/bin/bash
#
# Criar e configurar cluster
# no servidor de aplicação GlassFish
#
# Criação: 27/FEV/2013
# Autor: André Penteado

# Carregar Configurações
. ./config.sh
. ./global.sh

# Criar dominio [DAS]
$ASADMIN create-domain $DOMAIN
#$ASADMIN change-admin-password --domain_name $DOMAIN 
$ASADMIN start-domain $DOMAIN
$ASADMIN enable-secure-admin
$ASADMIN login
$ASADMIN stop-domain $DOMAIN
$ASADMIN start-domain $DOMAIN
$ASADMIN version --verbose

# Criar cluster
$ASADMIN create-cluster --properties GMS_DISCOVERY_URI_LIST=generate:GMS_LISTENER_PORT=9090 $CLUSTER

# Criar instâncias
for ((i=0; i < ${#NODES[@]}; i++))
do
   NAME_NODE=${NODES[$i]}
   $ASADMIN install-node-ssh $NAME_NODE
   $ASADMIN create-node-ssh --nodehost $NAME_NODE $NAME_NODE

   for ((j=0; j < $INSTANCES_FOR_NODE; j++))
   do
      NAME_INSTANCE=$NAME_NODE-instancia0$(($j+1))
      AJP_PORT=$((8009+$j))
      $ASADMIN create-instance --cluster $CLUSTER --node $NAME_NODE $NAME_INSTANCE
      $ASADMIN create-system-properties --target $NAME_INSTANCE AJP_INSTANCE=$NAME_INSTANCE
      $ASADMIN create-system-properties --target $NAME_INSTANCE AJP_PORT=$AJP_PORT

      # Caso haja configurado IPs de mais de uma interface no mesmo servidor
      if [ -n "$EXTERNAL_ADDR" ] && [ -n "$CONNECTION_ADDR" ]
      then
         $ASADMIN create-system-properties --target $NAME_INSTANCE EXTERNAL-ADDR=${EXTERNAL_ADDR[$(($j+1))]}
         $ASADMIN create-system-properties --target $NAME_INSTANCE GMS-BIND-INTERFACE-ADDRESS-$CLUSTER=${CONNECTION_ADDR[$(($j+1))]}
      fi
   done
done

# Integração com apache [protocolo AJP]
$ASADMIN create-network-listener --target $CLUSTER --listenerport \${AJP_PORT} --protocol http-listener-1 --jkenabled true jk-listener
$ASADMIN set $CLUSTER-config.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size=$USERS_CONNECTIONS
$ASADMIN create-jvm-options --target $CLUSTER "-DjvmRoute=\${AJP_INSTANCE}"

# Caso haja configurado IPs de mais de uma interface no mesmo servidor
if [ -n "$EXTERNAL_ADDR" ] && [ -n "$CONNECTION_ADDR" ]
then
   $ASADMIN create-system-properties --target server EXTERNAL-ADDR=${EXTERNAL_ADDR[0]}
   $ASADMIN create-system-properties --target server GMS-BIND-INTERFACE-ADDRESS-$CLUSTER=${CONNECTION_ADDR[0]}
   $ASADMIN set $CLUSTER-config.network-config.network-listeners.network-listener.http-listener-1.address=\${EXTERNAL-ADDR}
   $ASADMIN set $CLUSTER-config.network-config.network-listeners.network-listener.http-listener-2.address=\${EXTERNAL-ADDR}
   $ASADMIN set $CLUSTER-config.network-config.network-listeners.network-listener.jk-listener.address=\${EXTERNAL-ADDR}
fi
# Setar parâmetros para a JVM
$ASADMIN delete-jvm-options --target $CLUSTER -- -client
$ASADMIN create-jvm-options --target $CLUSTER -- -server
$ASADMIN delete-jvm-options --target $CLUSTER -- -Xmx512m
$ASADMIN create-jvm-options --target $CLUSTER -- -Xmx$JAVA_MX
$ASADMIN delete-jvm-options --target $CLUSTER -- "-XX\:MaxPermSize=192m"
$ASADMIN create-jvm-options --target $CLUSTER -- "-XX\:MaxPermSize=$JAVA_PERMGEN"
$ASADMIN create-jvm-options --target $CLUSTER -- "-XX\:+UseG1GC"
$ASADMIN create-jvm-options --target $CLUSTER -Duser.language=pt
$ASADMIN create-jvm-options --target $CLUSTER -Duser.country=BR
$ASADMIN create-jvm-options --target $CLUSTER -Duser.timezone=America/Sao_Paulo

# Carregar todas novas configurações
$ASADMIN stop-domain $DOMAIN
$ASADMIN start-domain $DOMAIN
$ASADMIN start-cluster $CLUSTER

echo "\n\nFIM DE EXECUÇÃO: Inicio: $INIT - Fim: `date \"+%Hh%Mm\"`\n\n"
