#!/bin/bash
# ============================================================================================
# File: ........: tanzu-postgres-pgbackrest.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/backup-restore.html
# https://pgbackrest.org/

export NAMESPACE="tanzu-data-postgres-demo"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                       _____                       ____        _                      '
echo '                      |_   _|_ _ _ __  _____   _  |  _ \  __ _| |_ __ _               '
echo '                        | |/ _  |  _ \|_  / | | | | | | |/ _  | __/ _  |              '
echo '                        | | (_| | | | |/ /| |_| | | |_| | (_| | || (_| |              '
echo '                        |_|\__,_|_| |_/___|\__,_| |____/ \__,_|\__\__,_|              '
echo '                                                                                      '
echo '               ____           _                        ____                           '
echo '              |  _ \ ___  ___| |_ __ _ _ __ ___  ___  |  _ \  ___ _ __ ___   ___      '
echo '              | |_) / _ \/ __| __/ _  |  __/ _ \/ __| | | | |/ _ \  _   _ \ / _ \     '
echo '              |  __/ (_) \__ \ || (_| | | |  __/\__ \ | |_| |  __/ | | | | | (_) |    '
echo '              |_|   \___/|___/\__\__, |_|  \___||___/ |____/ \___|_| |_| |_|\___/     '
echo '                                 |___/                                                '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '          VMware Tanzu Data for Postgres - Instance Backup (pgBackRest) to S3 (minio) '
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_SERVICE_TANZU_DATA_POSTGRES "Tanzu Data Postgres"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_SERVICE_MINIO_ACCESS_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_ACCESS_KEY)
TDH_SERVICE_MINIO_SECRET_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_SECRET_KEY)
DOMAIN=${TDH_LB_CONTOUR}

if [ ! -x "/usr/local/bin/docker" ]; then 
  echo "ERROR: Docker binaries are not installed"
  echo "       => brew install docker"
  exit 1
fi

if [ ! -x "/usr/local/bin/psql" ]; then
  echo "ERROR: Postgres binaries are not installed"
  echo "       => brew install postgresql"
  exit 1
fi

if [ ! -x "/usr/local/bin/mc" ]; then
  echo "ERROR: Minio Client binaries are not installed"
  echo "       => brew install minio/stable/mc"
  exit 1
fi

if [ ! -x "/usr/local/bin/s3cmd" ]; then 
  echo "ERROR: s3cmd binaries are not installed"
  echo "       => brew install s3cmd"
  exit 1
fi

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
    PRIMARY_INSTANCE=$(kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state' | \
                               grep "primary" | awk '{ print $5 }' | awk -F'.' '{ print $1 }') 
    INSTANCE=tdh-postgres-ha
    DBNAME=tdh-postgres-db
  fi
fi

mc rb minio/tdh-postgres-backup --force > /dev/null 2>&1

prtHead "Create S3 Bucket"
execCmd "mc mb minio/tdh-postgres-backup"
execCmd "mc ls minio"

prtHead "Create the PostgreSQL Backup Configuration (pgBackRest stanza) on S3 Storage"
prtText "A stanza defines the backup configuration for a specific PostgreSQL database cluster"
prtRead "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest stanza-create --stanza=\${BACKUP_STANZA_NAME}'"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest stanza-create --stanza=${BACKUP_STANZA_NAME}'
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

prtHead "Verify the Backup (pgBackRest stanza)"
prtRead "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest check --stanza=\${BACKUP_STANZA_NAME}'"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest check --stanza=${BACKUP_STANZA_NAME}'
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

prtHead "Now perform a backup of a Postgres instance (pgBackRest backup)"
prtRead "kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest backup --stanza=\${BACKUP_STANZA_NAME} --type=full backup"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE exec -it $PRIMARY_INSTANCE -- bash -c 'pgbackrest backup --stanza=${BACKUP_STANZA_NAME}'
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

prtHead "Use Minio CLI to verify the Backup"
prtText "=> mc alias set minio https://minio.${DOMAIN} $TDH_SERVICE_MINIO_ACCESS_KEY $TDH_SERVICE_MINIO_SECRET_KEY"
prtText "=> mc ls minio"
prtText ""

prtHead "Open WebBrowser and verify the Backup"
prtText "=> https://minio.${DOMAIN}"
prtText "   ACCESS_KEY: $TDH_SERVICE_MINIO_ACCESS_KEY"
prtText "   SECRET_LEY: $TDH_SERVICE_MINIO_SECRET_KEY"
prtText ""

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
