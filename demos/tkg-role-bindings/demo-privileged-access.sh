#!/bin/bash
# ============================================================================================
# File: ........: demo-privileged-access.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

export NAMESPACE="role-binding-demo"
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
echo '                   ____       _        ____  _           _ _                          '
echo '                  |  _ \ ___ | | ___  | __ )(_)_ __   __| (_)_ __   __ _ ___          '
echo '                  | |_) / _ \| |/ _ \ |  _ \| |  _ \ / _` | |  _ \ / _  / __|         '
echo '                  |  _ < (_) | |  __/ | |_) | | | | | (_| | | | | | (_| \__ \         '
echo '                  |_| \_\___/|_|\___| |____/|_|_| |_|\__,_|_|_| |_|\__, |___/         '
echo '                                                                   |___/              '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                       Role Binding - Allow Privileged Containers                     '
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

prtHead "Create namespace $NAMESPACE to host the Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "Create deployment for the ingress tesing app"
execCmd "kubectl create deployment echoserver --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
sleep 3
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Investigate the failed pod"
podname=$(kubectl get pods -n role-binding-demo | grep "CreateContainerConfigError" | awk '{ print $1 }')
execCmd "kubectl describe pod $podname -n $NAMESPACE"
read x

prtHead "Create Policy to Allow Privileged Containers"
execCmd "kubectl create rolebinding tanzu-demo-hub-privileged-$NAMESPACE-role-binding \\
          --clusterrole=vmware-system-tmc-psp-privileged \\
          --group=system:authenticated \\
          -n $NAMESPACE"

prtHead "See all Role Bindings"
execCmd "kubectl -n $NAMESPACE get rolebinding"

prtHead "Restart Deployment"
execCmd "kubectl -n $NAMESPACE rollout restart deployment echoserver"
execCmd "kubectl -n $NAMESPACE get pods"

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment echoserver --type LoadBalancer --port=8080 -n $NAMESPACE"
sleep 3
execCmd "kubectl -n $NAMESPACE get svc,pods"

ipa=$(kubectl -n $NAMESPACE get service/echoserver -o json | jq -r '.status.loadBalancer.ingress[].hostname')
prtHead "Open WebBrowser and verify the deployment"
echo "     => curl http://${ipa}:8080"
echo ""

exit

