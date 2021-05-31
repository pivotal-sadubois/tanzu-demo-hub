#!/bin/bash
# ============================================================================================
# File: ........: 03_tanzu-postgres-pgbackrest.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Category .....: VMware Tanzu Data for Postgres
# Description ..: Instance Backup (pgBackRest) to S3 (minio)
# ============================================================================================

export TDHDEMO=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHHOME=$(cd "$(pwd)/$(dirname $0)/../../.."; pwd)
export NAMESPACE="tanzu-data-postgres-demo"
export TDHDEMO_ABORT_ON_FAILURE=1
export DEBUG=0
export first=1

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
########################## TANZU DATA FOR POSTGRESS - POSTGRES BACKUP AND RESTORE DEMO ##################################
#########################################################################################################################

selfTestInit "Tanzu Data for Postgres - Instance Backup (pgBackRest) to S3 (minio)" 8
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

# --- CLEANUP ---
mc rb minio/tdh-postgres-backup --force > /dev/null 2>&1
selfTestStep "mc mb minio/tdh-postgres-backup"
selfTestStep "mc ls minio"

selfTestStep "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest stanza-create --stanza=\${BACKUP_STANZA_NAME}'"
selfTestStep "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest check --stanza=\${BACKUP_STANZA_NAME}'"
selfTestStep "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest backup --stanza=\${BACKUP_STANZA_NAME}'"

selfTestStep "mc alias set minio https://minio.${DOMAIN} $TDH_SERVICE_MINIO_ACCESS_KEY $TDH_SERVICE_MINIO_SECRET_KEY"
selfTestStep "mc ls minio/tdh-postgres-backup/"

selfTestFine
