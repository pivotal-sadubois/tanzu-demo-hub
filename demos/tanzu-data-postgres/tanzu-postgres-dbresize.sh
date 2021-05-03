#!/bin/bash
# ============================================================================================
# File: ........: tanzu-postgress-dbresize.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Category .....: VMware Tanzu Data for Postgres
# Description ..: Database Resize (CPU, Memory and Disk) 
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/update-instances.html

export TDH_DEMO_DIR="tanzu-data-postgres"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*$TDH_DEMO_DIR\).*+\1+g") 
export NAMESPACE="tanzu-data-postgres-demo"

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
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
echo '             VMware Tanzu Data for Postgres - Database Resize (CPU, Memory and Disk)  '
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
#verifyRequiredServices TDH_SERVICE_TANZU_DATA_POSTGRES "Tanzu Data Postgres"
#verifyRequiredServices TDH_SERVICE_MINIO               "Minio S3 Srorage"

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

INSTANCE=tdh-postgres-singleton
DBNAME=tdh-postgres-db

dbcpu=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')
dbmem=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')

prtHead "Verify Database ($INSTANCE) status"
execCmd "kubectl -n $NAMESPACE get pods"

dbname=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -D)
dbuser=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -D)
dbpass=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -D)
dbhost=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
dbport=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}')

prtText "List databases and access privileges"
execCmd "echo \"\l\" | PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser"

prtHead "Get current Memory and CPU setting on instance ($INSTANCE)"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
slntCmd "dbmem=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')"
echo -e "        dbmem=$dbmem\n"
slntCmd "dbcpu=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')"
echo -e "        dbcpu=$dbcpu"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

prtHead "Modify the memory and CPU allocation on the running instance ($INSTANCE)"
cat $TDHDEMO/files/tdh-postgres-singleton.yaml | sed -e "s/XXX_MEM_XXX/1Gi/g" -e "s/XXX_CPU_XXX/0.4/g" -e "s/XXX_DISK_XXX/10G/g" \
  > /tmp/tdh-postgres-singleton.yaml
execCat "/tmp/tdh-postgres-singleton.yaml"
execCmd "kubectl -n $NAMESPACE apply -f /tmp/tdh-postgres-singleton.yaml"

dbmem=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')
dbcpu=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')

prtHead "Get current Memory and CPU setting on instance ($INSTANCE)"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
slntCmd "dbmem=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')"
echo -e "        dbmem=$dbmem\n"
slntCmd "dbcpu=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')"
echo -e "        dbcpu=$dbcpu"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

dbdsk=$(kubectl -n $NAMESPACE get postgres tdh-postgres-singleton -o jsonpath='{.spec.storageSize}')

prtHead "Check current Storage Volume Size"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
slntCmd "dbdsk=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.storageSize}')"
echo -e "        dbdsk=$dbdsk"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
execCmd "kubectl -n tanzu-data-postgres-demo get pvc"

prtHead "Check the standard storage class’s 'allowVolumeExpansion' attribute value"
execCmd "kubectl get storageclass standard"

volex=$(kubectl get storageclass standard -o jsonpath='{.allowVolumeExpansion}') 
if [ "${volex}" != "true" ]; then 
  prtHead "Modify the storage class after checking the permissions"
  execCmd "kubectl auth can-i update storageclass"
  slntCmd "kubectl get storageclass standard -o yaml > /tmp/storagesize.yaml"
  slntCmd "echo \"allowVolumeExpansion: true\" >> /tmp/storagesize.yaml"
  execCat "/tmp/storagesize.yaml"
  execCmd "kubectl apply -f /tmp/storagesize.yaml"
  slntCmd "kubectl get storageclass standard --output=jsonpath='{.allowVolumeExpansion}'"; echo
  echo ""
fi

# --- GENERATE NEW YAML ---
cat $TDHDEMO/files/tdh-postgres-singleton.yaml | sed -e "s/XXX_MEM_XXX/1Gi/g" -e "s/XXX_CPU_XXX/0.4/g" -e "s/XXX_DISK_XXX/20G/g" \
  > /tmp/tdh-postgres-singleton.yaml
execCat "/tmp/tdh-postgres-singleton.yaml"
execCmd "kubectl -n $NAMESPACE apply -f /tmp/tdh-postgres-singleton.yaml"

dbdsk=$(kubectl -n $NAMESPACE get postgres tdh-postgres-singleton -o jsonpath='{.spec.storageSize}')

prtHead "Verify current Storage Volume Size"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
slntCmd "dbdsk=\$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.storageSize}')"
echo -e "        dbdsk=$dbdsk"
echo "     -------------------------------------------------------------------------------------------------------------------------------------------------------"
execCmd "kubectl -n tanzu-data-postgres-demo get pvc"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit

