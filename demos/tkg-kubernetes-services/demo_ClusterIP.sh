#!/bin/bash
# ============================================================================================
# File: ........: demo_ClusterIP.sh
# Cathegroy ....: tkg-kubernetes-services
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy an app with Service Type ClusterIP
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="my-app-demo"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# --------------------------------------------------------------------------------------------
# REQUIRED DOCKER ACCESS CREDENTIALS FROM ($HOME/.tanzu-demo-hub.cfg) FOR (dockerRateLimit) 
# --------------------------------------------------------------------------------------------
# TDH_REGISTRY_DOCKER_NAME ........... Docker Registry Name
# TDH_REGISTRY_DOCKER_USER ........... Docker Registry User
# TDH_REGISTRY_DOCKER_PASS ........... Docker Registry Password
# --------------------------------------------------------------------------------------------
[ -f $HOME/.tanzu-demo-hub.cfg ] && $HOME/.tanzu-demo-hub.cfg

# Created by /usr/local/bin/figlet
clear
echo ''
echo '                  ____                  _            _____                            '
echo '                 / ___|  ___ _ ____   _(_) ___ ___  |_   _|   _ _ __   ___            '
echo '                 \___ \ / _ \  __\ \ / / |/ __/ _ \   | || | | |  _ \ / _ \           '
echo '                  ___) |  __/ |   \ V /| | (_|  __/   | || |_| | |_) |  __/           '
echo '                 |____/ \___|_|    \_/ |_|\___\___|   |_| \__  |  __/ \___|           '
echo '                                                          |___/|_|                    '
echo '                           ____ _           _           ___ ____                      '
echo '                          / ___| |_   _ ___| |_ ___ _ _|_ _|  _ \                     '
echo '                         | |   | | | | / __| __/ _ \  __| || |_) |                    '
echo '                         | |___| | |_| \__ \ ||  __/ |  | ||  __/                     '
echo '                          \____|_|\____|___/\__\___|_| |___|_|                        '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '              Deploy application (my-app) with Service Type ClusterIP                 '
echo '                               by Sacha Dubois, VMware Inc                            '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_INGRESS_CONTOUR_LB_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_INGRESS_CONTOUR_LB_IP=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_IP)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
DOMAIN=${TDH_INGRESS_CONTOUR_LB_DOMAIN}

# --- CLEANUP DEPLOYMENT ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1
[ -f /tmp/proxy_pid ] && read pid < /tmp/proxy_pid && kill $pid > /dev/null 2>&1

prtHead "Create a namespace to host the Demo"
execCmd "kubectl create namespace $NAMESPACE"

# --- PATCH DEFAULT SERVICE ACCOUNT IN NAMESPACE ---
dockerRateLimit $NAMESPACE > /dev/null 2>&1

prtHead "Create deployment for (my-app) basing on the (datamanos/echoserver) image"
execCmd "kubectl create deployment my-app --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create a Service Type ClusterIP for (my-app)"
execCmd "kubectl expose deployment my-app --port=8080 --type=ClusterIP -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Start a Proxy to the Kubernetes API on local Port 8080"
prtText "=> kubectl proxy --port=8080 &"
kubectl proxy --port=8080 > /dev/null 2>&1 & > /dev/null 2>&1
sleep 5
  echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  echo "     Starting to serve on 127.0.0.1:8080"
  echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo $! > /tmp/proxy_pid
echo ""

prtHead "Acess the Kubernetes ClusterIP Service (my-app)" 
execCmd "curl -s http://localhost:8080/api/v1/namespaces/$NAMESPACE/services/my-app/proxy/" 

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit





