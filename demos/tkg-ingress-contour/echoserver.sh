#!/bin/bash
# ============================================================================================
# File: ........: ingress_http.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="contour-ingress-demo"
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
echo '            ____            _                     ___                                 '                
echo '           / ___|___  _ __ | |_ ___  _   _ _ __  |_ _|_ __   __ _ _ __ ___  ___ ___   '
echo '          | |   / _ \|  _ \| __/ _ \| | | |  __|  | ||  _ \ / _  |  __/ _ \/ __/ __|  '
echo '          | |__| (_) | | | | || (_) | |_| | |     | || | | | (_| | | |  __/\__ \__ \  '
echo '           \____\___/|_| |_|\__\___/ \__,_|_|    |___|_| |_|\__  |_|  \___||___/___/  '
echo '                                                            |___/                     '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '              Contour Ingress Example with Domain and Context based Routing           '
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
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_LB_CONTOUR)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
DOMAIN=${TDH_LB_CONTOUR}.${TDH_ENVNAME}.${TDH_DOMAIN}

# --- CLEANUP DEPLOYMENT ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1

# --- PREPARATION ---
cat files/http-ingress.yaml | sed -e "s/DNS_DOMAIN/${TDH_LB_CONTOUR}.${TDH_ENVNAME}.${TDH_DOMAIN}/g" \
            -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/http-ingress.yaml

prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "Create deployment for the ingress tesing app"
execCmd "kubectl create deployment echoserver-1 --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
execCmd "kubectl create deployment echoserver-2 --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment echoserver-1 --port=8080 -n $NAMESPACE"
execCmd "kubectl expose deployment echoserver-2 --port=8080 -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
execCmd "cat /tmp/http-ingress.yaml"
execCmd "kubectl create -f /tmp/http-ingress.yaml"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     # --- Context Based Routing"
echo "     => curl http://echoserver.${DOMAIN}/foo"
echo "     => curl http://echoserver.${DOMAIN}/bar"
echo "     # --- Domain Based Routing"
echo "     => curl http://echoserver1.$DOMAIN"
echo "     => curl http://echoserver2.$DOMAIN"
echo ""

exit

#nginxdemos/hello
#TDH_TKGWC_NAME=tanzu-demo-hub
#K8S_CONTEXT=tanzu-demo-hub-admin@tanzu-demo-hub
#TKG_DEPLOYMENT=tkgmc-dev-azure-westeurope.cfg
#TDH_TKGMC_CONFIG=tkgmc-dev-azure-westeurope.yaml
#TKG_WC_CLUSTER=tkg-tanzu-demo-hub.cfg

  841  docker run -p 8888:80 shomika17/animals
  842  docker run -p 8887:80 shomika17/animals:latest
  843  docker run shomika17/animals:latest
  844  docker run -p 8887:80 bersling/animals
  845  docker run -p 8887:80 kritouf/animals
  846  docker run -p 8887:80 testingmky9394/docker-whale
  847  docker run -p 8887:80 amithrr/fortuneteller
  848  docker run -p 8887:80 paulbouwer/hello-kubernetes:1.8
  849  docker run -p 8887:8080 paulbouwer/hello-kubernetes:1.8
  863  docker run -p 8888:8080 gcr.io/google-samples/hello-app:1.0

export TDH_DEPLOYMENT_ENV_NAME="Azure"
export TKG_CONFIG=/Users/sdubois/workspace/tanzu-demo-hub/config/tkgmc-azure-westeurope.yaml





