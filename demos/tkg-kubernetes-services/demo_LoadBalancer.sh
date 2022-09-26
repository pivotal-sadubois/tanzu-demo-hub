#!/bin/bash
# ============================================================================================
# File: ........: demo_LoadBalancer.sh
# Cathegroy ....: tkg-kubernetes-services
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy an app with Service Type LoadBalancer
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
echo '                   ____                  _            _____                           '
echo '                  / ___|  ___ _ ____   _(_) ___ ___  |_   _|   _ _ __   ___           '
echo '                  \___ \ / _ \  __\ \ / / |/ __/ _ \   | || | | |  _ \ / _ \          '
echo '                   ___) |  __/ |   \ V /| | (_|  __/   | || |_| | |_) |  __/          '
echo '                  |____/ \___|_|    \_/ |_|\___\___|   |_| \__, | .__/ \___|          '
echo '                                                           |___/|_|                   '
echo '                _                    _ ____        _                                  '
echo '               | |    ___   __ _  __| | __ )  __ _| | __ _ _ __   ___ ___ _ __        '
echo '               | |   / _ \ / _  |/ _  |  _ \ / _  | |/ _  |  _ \ / __/ _ \  __|       '
echo '               | |__| (_) | (_| | (_| | |_) | (_| | | (_| | | | | (_|  __/ |          '
echo '               |_____\___/ \__,_|\__,_|____/ \__,_|_|\__,_|_| |_|\___\___|_|          '
echo '                                                                                      '                                                                
echo '          ----------------------------------------------------------------------------'
echo '                 Deploy application (my-app) with Service Type LoadBalancer           '
echo '                                  by Sacha Dubois, VMware Inc                         '
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

prtHead "Create a namespace to host the Demo"
execCmd "kubectl create namespace $NAMESPACE"

# --- PATCH DEFAULT SERVICE ACCOUNT IN NAMESPACE ---
dockerRateLimit $NAMESPACE > /dev/null 2>&1

prtHead "Create deployment for (my-app) basing on the (datamanos/echoserver) image"
execCmd "kubectl create deployment my-app --image=datamanos/echoserver --port=8080 -n $NAMESPACE"

execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create a Service Type LoadBalancer for (my-app)"
execCmd "kubectl expose deployment my-app --port=8080 --type=LoadBalancer -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

# --- TKGS with AVI LoadBalancer ----
if [ "$TDH_ENVNAME" == "tkgs" ]; then 
  ipa=$(kubectl -n $NAMESPACE get service/my-app -o json | jq -r '.status.loadBalancer.ingress[].ip') 

  prtHead "Open WebBrowser and verify the deployment by using the LoadBalancer IP ($ipa)"
  execCmd "curl -s http://$ipa:8080"
  echo ""
fi

# --- TKG on Azure with Azure LoadBalancer ----
if [ "$TDH_ENVNAME" == "aztkg" ]; then 
  ipa=$(kubectl -n $NAMESPACE get service/my-app -o json | jq -r '.status.loadBalancer.ingress[].ip') 

  prtHead "Open WebBrowser and verify the deployment"
  echo "     Directly by the LoadBalancer IP Address"
  echo "     => curl http://$ipa:8080"
  echo ""
fi

# --- TKG on AWS with ELB LoadBalancer ----
if [ "$TDH_ENVNAME" == "awstkg" ]; then 
  alias=$(kubectl -n $NAMESPACE get service/my-app -o json | jq -r '.status.loadBalancer.ingress[].hostname') 

  ret=1; cnt=1
  while [ $ret -ne 0 -a $cnt -lt 10 ]; do
    nslookup $alias1 > /dev/null 2>&1; ret=$?
    [ $ret -eq 0 ] && break
  
    sleep 20
    let cnt=cnt+1
  done

  ipa=$(nslookup $alias | grep Address | tail -1 | awk '{ print $NF }')

  prtHead "Open WebBrowser and verify the deployment"
  echo "     AWS ELB Loadbalancer Name"
  echo "     => curl http://$alias:8080"
  echo ""
  echo "     Directly by the LoadBalancer IP Address"
  echo "     => curl http://$ipa:8080"
  echo ""
  echo ""
fi

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit


exit





