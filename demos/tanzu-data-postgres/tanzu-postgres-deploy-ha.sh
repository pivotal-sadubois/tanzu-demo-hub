#!/bin/bash
# ============================================================================================
# File: ........: demo-privileged-access.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/high-availability.html#verify_configuration
# kubectl exec -ti pod/my-postgres-ha-1 -- pg_autoctl show state

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
echo '               VMware Tanzu Data for Postgres - Deploy a High Available Database      '
echo '                                 by Sacha Dubois, VMware Inc                          '
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

INSTANCE=tdh-postgres-ha
DBNAME=tdh-postgres-db

# --- CLEANUP ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1
helm uninstall tdh-pgadmin > /dev/null 2>&1

prtHead "Tanzu SQL with Postgres - High Availability"
echo "     High availability offers automatic failover ensuring that any application requests"
echo "     operate continuously and without downtime. Please review the architecture here: "
echo "     => https://postgres-kubernetes.docs.pivotal.io/1-1/high-availability.html"
echo ""
echo -e "     presse 'return' to continue when ready\c"; read x

prtHead "Show the Tanzu Data with Postgres Helm Chart"
execCmd "helm list"
execCmd "helm status postgres-operator"
execCmd "kubectl get all"

prtHead "Create seperate namespace to host the Postgres Demo"
execCmd "kubectl create namespace $NAMESPACE"
execCmd "kubectl get namespace"

# --- PREPARATION ---
cat $TDHDEMO/files/minio-s3-secret-backup.yaml | sed -e "s/MINIO_ACCESS_KEY/$TDH_SERVICE_MINIO_ACCESS_KEY/g" \
  -e "s/MINIO_SECRET_KEY/$TDH_SERVICE_MINIO_SECRET_KEY/g" > /tmp/minio-s3-secret-backup.yaml

prtHead "Create S3 Secret (Minio) used for pgBackRest"
execCat "/tmp/minio-s3-secret-backup.yaml"
execCmd "kubectl -n $NAMESPACE apply -f /tmp/minio-s3-secret-backup.yaml"

prtHead "Create Database HA Instance"
execCat "$TDHDEMO/files/tdh-postgres-ha.yaml"
execCmd "kubectl -n $NAMESPACE create -f $TDHDEMO/files/tdh-postgres-ha.yaml"

sleep 30 

execCmd "kubectl -n $NAMESPACE get all"
execCmd "kubectl -n $NAMESPACE get pvc"
#execCmd "kubectl -n $NAMESPACE get pv"
helm uninstall tdh-pgadmin > /dev/null 2>&1

dbname=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -D)
dbuser=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -D)
dbpass=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -D)
dbhost=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
dbport=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}')

prtHead "Access the database with (psql) from outside"
slntCmd "dbname=\$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -D)"
echo -e "        dbname=$dbname\n"
slntCmd "dbuser=\$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -D)"
echo -e "        dbuser=$dbuser\n"
slntCmd "dbpass=\$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -D)"
echo -e "        dbpass=$dbpass\n"
slntCmd "dbhost=\$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo -e "        dbhost=$dbhost\n"
slntCmd "dbport=\$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}')"
echo -e "        dbport=$dbport\n"

prtHead "Connect Database with psql via external LB ($dbhost)"
prtRead "=> PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser"
prtText "     \l                                # List of Databases"
prtText "     \dr                               # List Roles"
prtText "     \dT                               # List Data Types"
prtText "     \?                                # List all Commands"
prtText "     select * from pg_hba_file_rules;  # Show pg_hba access rules"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

prtHead "Connect Database with psql within is pod ($INSTANCE-0)"
prtRead "=> kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c \"psql\""
prtText "     \l                                # List of Databases"
prtText "     \dr                               # List Roles"
prtText "     \dT                               # List Data Types"
prtText "     \?                                # List all Commands"
prtText "     select * from pg_hba_file_rules;  # Show pg_hba access rules"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c "psql"
echo "-------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

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
echo "        Name: \"tdh-postgres-db\""                                                                                    >> $HELM_VALUES
echo "        Group: \"Servers\""                                                                                           >> $HELM_VALUES
echo "        Port: 5432"                                                                                                   >> $HELM_VALUES
echo "        Username: \"$dbuser\""                                                                                        >> $HELM_VALUES
echo "        Password: \"$dbpass\""                                                                                        >> $HELM_VALUES
echo "        Host: \"$dbhost\""                                                                                            >> $HELM_VALUES
echo "        SSLMode: \"prefer\""                                                                                          >> $HELM_VALUES
echo "        MaintenanceDB: \"tdh-postgres-db\""                                                                           >> $HELM_VALUES
echo ""                                                                                                                     >> $HELM_VALUES

prtHead "Install and configure pgAdmin4 Helm Chart"
execCat "$HELM_VALUES"
slntCmd "helm install tdh-pgadmin cetic/pgadmin -f $HELM_VALUES --wait-for-jobs --wait > /dev/null 2>&1"
execCmd "helm status tdh-pgadmin"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://pgadmin.${DOMAIN}       # User: pgadmin4@pgadmin.org Password: admin DBpassword: $dbpass"
echo ""
echo -e "     presse 'return' to continue when ready\c"; read x
echo ""

pnode=$(kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state' | grep "primary" | awk '{ print $5 }' | awk -F'.' '{ print $1 }')
snode=$(kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state' | grep "secondary" | awk '{ print $5 }' | awk -F'.' '{ print $1 }')
prtHead "Check the Postgres Cluster Status"
execCmd "kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state'"
prtHead "Test Postgress Failover"
execCmd "kubectl -n tanzu-data-postgres-demo delete pod $pnode"
execCmd "kubectl -n tanzu-data-postgres-demo get pods"
execCmd "kubectl -n tanzu-data-postgres-demo get pods"
execCmd "kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state'"
execCmd "kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state'"
execCmd "kubectl -n tanzu-data-postgres-demo exec -it tdh-postgres-ha-0 -- bash -c 'pg_autoctl show state'"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
