#!/bin/bash
# ============================================================================================
# File: ........: tanzu-postgress-deploy-singleton.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

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
echo '            VMware Tanzu Data for Postgres - Build and attach an app to the database  '
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
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

# --- VERIFY TOOLS AND ACCESS ---
verify_docker
checkCLIcommands        BASIC
checkCLIcommands        DEMO_TOOLS
checkCLIcommands        TANZU_DATA

# --- HARBOR CONFIG ---
TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
if [ "$TDH_HARBOR_REGISTRY_ENABLED" != "true" ]; then 
  echo "ERROR: The Harbor registry is required to run this demo"
  exit
else
  docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: failed to login to registry"
    echo "       => docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
    exit
  fi
fi

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

# --- CLEANUP ---
docker builder prune -a -f > /dev/null 2>&1
kubectl -n $NAMESPACE delete deployment spring-music > /dev/null 2>&1
kubectl -n $NAMESPACE delete svc spring-music-service > /dev/null 2>&1
kubectl -n $NAMESPACE delete ingress tdh-spring-music > /dev/null 2>&1
kubectl -n $NAMESPACE delete secret tanzu-demo-hub-tls > /dev/null 2>&1
kubectl get secret tanzu-demo-hub-tls --namespace=default -oyaml | \
    grep -v namespace | kubectl apply --namespace=$NAMESPACE -f - > /dev/null

DBNAME=tdh-postgres-db

# --- ENVIRONMENT VARIABLES ---
DOCKER_BUILD_DIR=/tmp/docker_build
rm -rf $DOCKER_BUILD_DIR
cat sample-app/spring-music.yaml | sed -e "s/DB_INSTANCE/$INSTANCE/g" -e "s/DOMAIN/$DOMAIN/g" > /tmp/spring-music.yaml 

prtHead "Building the Spring Music Demo App"
prtText "=> https://github.com/cloudfoundry-samples/spring-music"
lineFed

prtHead "Create temporary Docker Build directory ($DOCKER_BUILD_DIR)"
slntCmd "mkdir -p $DOCKER_BUILD_DIR"
slntCmd "cp sample-app/* $DOCKER_BUILD_DIR"
lineFed

prtHead "Build the Docker Container"
execCmd "ls -la $DOCKER_BUILD_DIR"
execCat "$DOCKER_BUILD_DIR/Dockerfile"
execCat "$DOCKER_BUILD_DIR/start.sh"
execCmd "cd $DOCKER_BUILD_DIR && docker build -t spring-music:latest -f Dockerfile ."
execCmd "docker images spring-music"

prtHead "Push Docker container (busybox-no-digest:latest) to the Harbor Registry"
slntCmd "docker tag spring-music:latest $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-music:latest"
execCmd "docker push $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-music:latest"

prtHead "Deploy the app defined in the spring-music.yaml"
execCat "$DOCKER_BUILD_DIR/spring-music.yaml"
execCmd "kubectl -n $NAMESPACE create -f /tmp/spring-music.yaml"
sleep 15

prtHead "List the deployments, pods, and services in the Kubernetes cluster"
execCmd "kubectl -n $NAMESPACE get deployments"
execCmd "kubectl -n $NAMESPACE get pods"
execCmd "kubectl -n $NAMESPACE get services"
execCmd "kubectl -n $NAMESPACE get ingress"

prtHead "Verify that the spring-music app has created the album table in the testdb database"
execCmd "kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c \"psql tdh-postgres-db -c 'select count(*) from album;'\""

prtHead "Open WebBrowser and verify the deployment"
prtRead "     => https://spring-music.${DOMAIN}"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit

