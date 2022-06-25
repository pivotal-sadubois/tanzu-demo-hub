#!/bin/bash
# ============================================================================================
# File: ........: ingress_http.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="breathtestshiny"
export APPNAME="breathtestshiny"
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
echo '                                                                                      '
echo '           ____                 _   _   _____         _   ____  _     _               '
echo '          | __ ) _ __ ___  __ _| |_| |_|_   _|__  ___| |_/ ___|| |__ (_)_ __  _   _   '
echo '          |  _ \|  __/ _ \/ _  | __|  _ \| |/ _ \/ __| __\___ \|  _ \| |  _ \| | | |  '
echo '          | |_) | | |  __/ (_| | |_| | | | |  __/\__ \ |_ ___) | | | | | | | | |_| |  '
echo '          |____/|_|  \___|\__,_|\__|_| |_|_|\___||___/\__|____/|_| |_|_|_| |_|\__, |  '
echo '                                                                              |___/   '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                          Breth Test Shiny - Demo Application                         '
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

prtHead "Create seperate namespace to host the $APPNAME Demo"
execCmd "kubectl create namespace $NAMESPACE"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

prtHead "Create deployment for the ingress tesing app"
execCmd "kubectl create deployment $APPNAME --image=dmenne/breathtestshiny --port=3838 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create the service ($NAMESPACE)"
execCmd "kubectl expose deployment $APPNAME --port=3838 --type=LoadBalancer -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

ipa=$(kubectl -n $NAMESPACE get service/$APPNAME -o json | jq -r '.status.loadBalancer.ingress[].ip') 

prtHead "Open WebBrowser and verify the deployment"
echo "        # loopup with the AWS Loadbalancer IP Address"
echo "     => http://$ipa:3838"
echo ""
echo ""

exit





