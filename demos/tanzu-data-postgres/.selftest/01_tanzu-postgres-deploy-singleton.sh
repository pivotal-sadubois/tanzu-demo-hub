#!/bin/bash

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
########################## TANZU DATA FOR POSTGRESS - DEPLOY A SINGLE INSTANCE DATABASE  ################################
#########################################################################################################################

selfTestInit "Tanzu Data for Postgres - Deploy a Single Instance Database" 21
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
INSTANCE=tdh-postgres-singleton
DBNAME=tdh-postgres-db

# --- CLEANUP ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1
helm uninstall tdh-pgadmin > /dev/null 2>&1

selfTestStep "helm list"
selfTestStep "kubectl get all"
selfTestStep "helm status postgres-operator"
selfTestStep "kubectl create namespace $NAMESPACE"
selfTestStep "kubectl get namespace"

# --- PREPARATION ---
cat $TDHDEMO/files/minio-s3-secret-backup.yaml | \
sed -e "s/MINIO_ACCESS_KEY/$TDH_SERVICE_MINIO_ACCESS_KEY/g" \
  -e "s/MINIO_SECRET_KEY/$TDH_SERVICE_MINIO_SECRET_KEY/g" > /tmp/minio-s3-secret-backup.yaml

selfTestStep "kubectl -n $NAMESPACE apply -f /tmp/minio-s3-secret-backup.yaml"
selfTestStep "kubectl -n $NAMESPACE create -f $TDHDEMO/files/tdh-postgres-singleton.yaml"
selfTestStep "kubectl -n $NAMESPACE get all"
selfTestStep "kubectl -n $NAMESPACE get pvc"

# --- GIVE PODS TIME TO START ---
sleep 20

# --- TEST RETRIEVING SECRETS ---
selfTestStep "kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}'"
selfTestStep "kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}'"
selfTestStep "kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}'"
selfTestStep "kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
selfTestStep "kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}'"

dbname=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.dbname}' | base64 -D)
dbuser=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.username}' | base64 -D)
dbpass=$(kubectl -n $NAMESPACE get secrets $INSTANCE-db-secret -o jsonpath='{.data.password}' | base64 -D)
dbhost=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
dbport=$(kubectl -n $NAMESPACE get service $INSTANCE -o jsonpath='{.spec.ports[0].port}')

selfTestStep "PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser -f sql/tdh_info.sql"
selfTestStep "echo \"select * from pg_hba_file_rules;\" | PGPASSWORD=$dbpass psql -h $dbhost -p $dbport -d $dbname -U $dbuser"
selfTestStep "echo \"select * from pg_hba_file_rules;\" | kubectl -n $NAMESPACE exec -it $INSTANCE-0 -- bash -c psql"

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

selfTestStep "helm install tdh-pgadmin cetic/pgadmin -f $HELM_VALUES --wait-for-jobs --wait"
selfTestStep "helm status tdh-pgadmin"
selfTestStep "curl https://pgadmin.${DOMAIN}"

selfTestFine

exit

