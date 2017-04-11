#!/bin/bash
#
# Desinstalar cluster e dominio sistemas-unesp
# Criação: 06/AGO/2013
# Autor: André Penteado

# Carregar Configurações
. ./config.sh
. ./global.sh

$ASADMIN stop-cluster $CLUSTER

for ((i=0; i < ${#NODES[@]}; i++))
do
   for ((j=0; j < $INSTANCES_FOR_NODE; j++))
   do
      NAME_INSTANCE=$NAME_NODE-instancia0$(($j+1))
      $ASADMIN delete-instance $NAME_INSTANCE
   done
   NAME_NODE=${NODES[$i]}
   $ASADMIN uninstall-node-ssh $NAME_NODE
done

$ASADMIN delete-cluster $CLUSTER
$ASADMIN stop-domain $DOMAIN
$ASADMIN delete-domain $DOMAIN
