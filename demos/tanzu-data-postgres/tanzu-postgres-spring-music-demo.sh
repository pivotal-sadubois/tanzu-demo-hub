#!/bin/bash
# ============================================================================================
# File: ........: tanzu-postgress-deploy-singleton.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

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
echo '            VMware Tanzu Data for Postgres - Build and attach an app to the database  '
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
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
  echo "ERROR: No database has been deployed, please run eaither:"
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
prtRead "     => https://github.com/cloudfoundry-samples/spring-music"
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

prtHead "List the deployments, pods, and services in the Kubernetes cluster"
execCmd "kubectl -n $NAMESPACE get deployments"
execCmd "kubectl -n $NAMESPACE get pods"
execCmd "kubectl -n $NAMESPACE get services"
execCmd "kubectl -n $NAMESPACE get ingress"

prtHead "Verify that the spring-music app has created the album table in the testdb database"
execCmd "kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c \"psql tdh-postgres-db -c 'select count(*) from album;'\""

prtHead "Open WebBrowser and verify the deployment"
prtRead "     => https://spring-music.${DOMAIN}"

exit

if [ 1 -eq 1 ]; then
# --- CLEANUP ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1
helm uninstall tdh-pgadmin > /dev/null 2>&1

prtHead "Show the Tanzu Data with Postgres Helm Chart"
execCmd "helm list"
execCmd "helm status postgres-operator"
execCmd "kubectl get all"

prtHead "Create seperate namespace to host the Postgres Demo"
execCmd "kubectl create namespace $NAMESPACE"
execCmd "kubectl get namespace"

prtHead "Create TMC Workspace for Production and Testing ressources"
execCat "files/tdh-postgres-singleton.yaml"
execCmd "kubectl -n $NAMESPACE create -f files/tdh-postgres-singleton.yaml"
execCmd "kubectl -n $NAMESPACE get all"
execCmd "kubectl -n $NAMESPACE get pvc"
execCmd "kubectl -n $NAMESPACE get pv"
fi
helm uninstall tdh-pgadmin > /dev/null 2>&1

dbname=$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.dbname}' | base64 -D)
dbuser=$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.username}' | base64 -D)
dbpass=$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.password}' | base64 -D)
dbhost=$(kubectl -n $NAMESPACE get service $DBNAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
dbport=$(kubectl -n $NAMESPACE get service $DBNAME -o jsonpath='{.spec.ports[0].port}')

prtHead "Access the database with (psql) from outside"
slntCmd "dbname=\$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.dbname}' | base64 -D)"
echo -e "        dbname=$dbname\n"
slntCmd "dbuser=\$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.username}' | base64 -D)"
echo -e "        dbuser=$dbuser\n"
slntCmd "dbpass=\$(kubectl -n $NAMESPACE get secrets $DBNAME-db-secret -o jsonpath='{.data.password}' | base64 -D)"
echo -e "        dbpass=$dbpass\n"
slntCmd "dbhost=\$(kubectl -n $NAMESPACE get service $DBNAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo -e "        dbhost=$dbhost\n"
slntCmd "dbport=\$(kubectl -n $NAMESPACE get service $DBNAME -o jsonpath='{.spec.ports[0].port}')"
echo -e "        dbport=$dbport\n"

prtHead "Connect with psql via external LB ($dbhost)"
echo -e "     => PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser\c"; read x
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser 
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

#prtHead "Connect  psql via external LB ($dbhost)"
#echo "kubectl -n $NAMESPACE exec -it example-0 -- bash -c "psql""
#kubectl -n $NAMESPACE exec -it $DBNAME-0 -- bash -c "psql"

HELM_VALUES=/tmp/helm_values.yaml
echo ""                                                                                                                     >  $HELM_VALUES
echo "pgadmin:"                                                                                                             >> $HELM_VALUES
echo "  ## pgadmin admin user"                                                                                              >> $HELM_VALUES
echo "  username: pgadmin4@pgadmin.org"                                                                                     >> $HELM_VALUES
echo "  ##pgadmin admin password"                                                                                           >> $HELM_VALUES
echo "  password: admin"                                                                                                    >> $HELM_VALUES
echo "  tls: false"                                                                                                         >> $HELM_VALUES
echo "service:"                                                                                                             >> $HELM_VALUES
echo "  name: pgadmin"                                                                                                      >> $HELM_VALUES
echo "  type: ClusterIP"                                                                                                    >> $HELM_VALUES
echo "  port: 80"                                                                                                           >> $HELM_VALUES
echo "  tlsport: 443"                                                                                                       >> $HELM_VALUES
echo "ingress:"                                                                                                             >> $HELM_VALUES
echo "  enabled: true"                                                                                                      >> $HELM_VALUES
echo "  annotations:"                                                                                                       >> $HELM_VALUES
echo "    kubernetes.io/ingress.class: contour"                                                                             >> $HELM_VALUES
echo "    ingress.kubernetes.io/force-ssl-redirect: \"true\""                                                               >> $HELM_VALUES
echo "  path: /"                                                                                                            >> $HELM_VALUES
echo "  hosts:"                                                                                                             >> $HELM_VALUES
echo "    - pgadmin.$DOMAIN"                                                                                                >> $HELM_VALUES
echo "  tls:"                                                                                                               >> $HELM_VALUES
echo "    - hosts:"                                                                                                         >> $HELM_VALUES
echo "      - pgadmin.$DOMAIN"                                                                                              >> $HELM_VALUES
echo "      secretName: tanzu-demo-hub-tls"                                                                                 >> $HELM_VALUES
echo "servers:"                                                                                                             >> $HELM_VALUES
echo "  enabled: true"                                                                                                      >> $HELM_VALUES
echo "  config:"                                                                                                            >> $HELM_VALUES
echo "    Servers:"                                                                                                         >> $HELM_VALUES
echo "      1:"                                                                                                             >> $HELM_VALUES
echo "        Name: \"tdh-postgres-singleton\""                                                                             >> $HELM_VALUES
echo "        Group: \"Servers\""                                                                                           >> $HELM_VALUES
echo "        Port: 5432"                                                                                                   >> $HELM_VALUES
echo "        Username: \"$dbuser\""                                                                                        >> $HELM_VALUES
echo "        Password: \"$dbpass\""                                                                                        >> $HELM_VALUES
echo "        Host: \"$dbhost\""                                                                                            >> $HELM_VALUES
echo "        SSLMode: \"prefer\""                                                                                          >> $HELM_VALUES
echo "        MaintenanceDB: \"tdh-postgres-singleton\""                                                                    >> $HELM_VALUES
echo ""                                                                                                                     >> $HELM_VALUES

prtHead "Install and configure pgAdmin4 Helm Chart"
execCat "$HELM_VALUES"
execCmd "helm install tdh-pgadmin cetic/pgadmin -f $HELM_VALUES" 

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://pgadmin.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "pgadmin.apps-contour.$TDH_ENVNAME.$AWS_HOSTED_DNS_DOMAIN"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
