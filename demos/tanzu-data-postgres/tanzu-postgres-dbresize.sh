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
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tanzu-data-postgres-demo"

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

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

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
runTDHtoolsDemos

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_SERVICE_TANZU_DATA_POSTGRES "Tanzu Data Postgres"
verifyRequiredServices TDH_SERVICE_MINIO               "Minio S3 Srorage"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_SERVICE_MINIO_ACCESS_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_ACCESS_KEY)
TDH_SERVICE_MINIO_SECRET_KEY=$(getConfigMap tanzu-demo-hub TDH_SERVICE_MINIO_SECRET_KEY)
DOMAIN=${TDH_LB_CONTOUR}

# --- VERIFY TOOLS AND ACCESS ---
verify_docker
checkCLIcommands        BASIC
checkCLIcommands        DEMO_TOOLS
checkCLIcommands        TANZU_DATA

kubectl -n tanzu-data-postgres-demo get pod tdh-postgres-singleton-0 > /dev/null 2>&1; db_singleton=$?
kubectl -n tanzu-data-postgres-demo get pod tdh-postgres-ha-0 > /dev/null 2>&1; db_ha=$?

if [ $db_singleton -ne 0 -a $db_ha -ne 0 ]; then
  echo "ERROR: No database has been deployed, please run either:"
  echo "       => ./tanzu-postgres-deploy-singleton.sh or"
  echo "       => ./tanzu-postgres-deploy-ha.sh"
  exit
else
  [ $db_singleton -eq 0 ] && INSTANCE=tdh-postgres-singleton
  [ $db_ha -eq 0 ] && INSTANCE=tdh-postgres-ha
  DBNAME=tdh-postgres-db
fi

dbcpu=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.cpu}')
dbmem=$(kubectl -n $NAMESPACE get postgres/$INSTANCE -o jsonpath='{.spec.memory}')

prtHead "Verify Database ($INSTANCE) status"
execCmd "kubectl -n $NAMESPACE get pods"

dbname=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -d)
dbuser=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -d)
dbpass=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -d)
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

# --- GET THE KUBERNETES DEFAULT STORAGE CLASSE ---
cmdLoop kubectl get sc -o json > /tmp/output.json
STORAGE_CLASS=$(jq -r '.items[].metadata | select(.annotations."storageclass.kubernetes.io/is-default-class" == "true").name' /tmp/output.json)
[ "$STORAGE_CLASS" == "" ] && STORAGE_CLASS=standard

prtHead "Modify the memory and CPU allocation on the running instance ($INSTANCE)"
cat $TDHDEMO/files/tdh-postgres-singleton.yaml | sed -e "s/XXX_MEM_XXX/1Gi/g" -e "s/XXX_CPU_XXX/0.4/g" -e "s/XXX_DISK_XXX/10G/g" \
  -e "s/XXX_STARTE_CLASS_XXX/$STORAGE_CLASS/g" \
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
execCmd "kubectl get storageclass $STORAGE_CLASS"

volex=$(kubectl get storageclass $STORAGE_CLASS -o jsonpath='{.allowVolumeExpansion}') 
if [ "${volex}" != "true" ]; then 
  prtHead "Modify the storage class after checking the permissions"
  execCmd "kubectl auth can-i update storageclass"
  slntCmd "kubectl get storageclass $STORAGE_CLASS -o yaml > /tmp/storagesize.yaml"
  slntCmd "echo \"allowVolumeExpansion: true\" >> /tmp/storagesize.yaml"
  execCat "/tmp/storagesize.yaml"
  execCmd "kubectl apply -f /tmp/storagesize.yaml"
  slntCmd "kubectl get storageclass $STORAGE_CLASS --output=jsonpath='{.allowVolumeExpansion}'"; echo
  echo ""
fi

# --- GENERATE NEW YAML ---
cat $TDHDEMO/files/tdh-postgres-singleton.yaml | sed \
  -e "s/XXX_MEM_XXX/1Gi/g" \
  -e "s/XXX_CPU_XXX/0.4/g" \
  -e "s/XXX_DISK_XXX/20G/g" \
  -e "s/XXX_STARTE_CLASS_XXX/$STORAGE_CLASS/g" \
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

