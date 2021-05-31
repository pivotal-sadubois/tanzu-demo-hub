#!/bin/bash
# ============================================================================================
# File: ........: XX_tanzu-postgres-dbresize.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Category .....: VMware Tanzu Data for Postgres
# Description ..: Database Resize (CPU, Memory and Disk) 
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/update-instances.html

export TDHDEMO=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHHOME=$(cd "$(pwd)/$(dirname $0)/../../.."; pwd)
export NAMESPACE="tanzu-data-postgres-demo"
export TDHDEMO_ABORT_ON_FAILURE=1
export DEBUG=0
export first=1

# --- LOCAL VARIABLES ---
CAPACITY_MEMORY="800Mi"
CAPACITY_DISK="5G"
CAPACITY_CPU="0.2"

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --no_abort_on_failure)  TDHDEMO_ABORT_ON_FAILURE=0;;
    --debug)                DEBUG=1;;
  esac
  shift
done

#########################################################################################################################
########################## TANZU DATA FOR POSTGRESS - DEPLOY A SINGLE INSTANCE DATABASE  ################################
#########################################################################################################################

selfTestInit "Tanzu Data for Postgres - Database Resize (CPU, Memory and Disk)" 9
selfTestStep "kubectl get configmap tanzu-demo-hub"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_SERVICE_MINIO_ACCESS_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_ACCESS_KEY)
TDH_SERVICE_MINIO_SECRET_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_SECRET_KEY)
DOMAIN=${TDH_LB_CONTOUR}

kubectl -n tanzu-data-postgres-demo get pod tdh-postgres-singleton-0 > /dev/null 2>&1; db_singleton=$?
kubectl -n tanzu-data-postgres-demo get pod tdh-postgres-ha-0 > /dev/null 2>&1; db_ha=$?

if [ $db_singleton -ne 0 -a $db_ha -ne 0 ]; then
  echo "ERROR: No database has been deployed, please run eaither:"
  echo "       => ./tanzu-postgres-deploy-singleton.sh or"
  echo "       => ./tanzu-postgres-deploy-ha.sh"
  exit
else
  if [ $db_singleton -eq 0 ]; then
    INSTANCE=tdh-postgres-singleton
    DBNAME=tdh-postgres-db
    PRIMARY_INSTANCE=$INSTANCE-0
  else
    PRIMARY_INSTANCE=$(kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state' 2>/dev/null | \
                               grep "primary" | awk '{ print $5 }' | awk -F'.' '{ print $1 }')

    INSTANCE=tdh-postgres-ha
    DBNAME=tdh-postgres-db
  fi
fi

dbname=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -D)
dbuser=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -D)
dbpass=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -D)
dbhost=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
dbport=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}')

selfTestStep "PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser -f sql/tdh_info.sql"
selfTestStep "echo \"select * from pg_hba_file_rules;\" | PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser"
selfTestStep "echo \"select * from pg_hba_file_rules;\" | kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c psql"

# --- PREPARATION ---
cat $TDHDEMO/files/${INSTANCE}.yaml | sed -e "s/XXX_MEM_XXX/$CAPACITY_MEMORY/g" -e "s/XXX_CPU_XXX/$CAPACITY_CPU/g" -e "s/XXX_DISK_XXX/$CAPACITY_DISK/g" \
  > /tmp/${INSTANCE}.yaml

dbmem=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')
dbcpu=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')

selfTestStep "dbmem=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')"
selfTestStep "dbcpu=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')"

cat $TDHDEMO/files/${INSTANCE}.yaml | sed -e "s/XXX_MEM_XXX/1Gi/g" -e "s/XXX_CPU_XXX/0.4/g" -e "s/XXX_DISK_XXX/15G/g" \
  > /tmp/${INSTANCE}.yaml

selfTestStep "kubectl -n $NAMESPACE apply -f /tmp/${INSTANCE}.yaml"

dbmem=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')
dbcpu=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')

selfTestStep "dbmem=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')"
selfTestStep "dbcpu=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')"
selfTestFine

exit

