#!/bin/bash
# ============================================================================================
# File: ........: demo_ContourIngress.sh
# Cathegroy ....: tkg-kubernetes-services
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy an app with Service Type LoadBalancer
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="my-app-demo"
export DEMO_CATEGRORY="tkg-kubernetes-services"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$DEMO_CATEGRORY

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
TDH_INGRESS_CONTOUR_LB_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_INGRESS_CONTOUR_LB_IP=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_IP)
DOMAIN=${TDH_INGRESS_CONTOUR_LB_DOMAIN}

# --- CLEANUP DEPLOYMENT ---
kubectl delete namespace $NAMESPACE > /dev/null 2>&1

# --- PREPARATION ---
cat files/http-ingress.yaml | sed -e "s/DNS_DOMAIN/${TDH_INGRESS_CONTOUR_LB_DOMAIN}/g" \
            -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/http-ingress.yaml

prtHead "Show Tanzu Package for Countour Ingress Controller"
execCmd "tanzu package available list 2>/dev/null" 
execCmd "tanzu package installed list -A 2>/dev/null" 

prtHead "Get Contour Kubernetes objects (pod, svc)"
execCmd "kubectl -n tanzu-system-ingress get pods,svc"

prtHead "Show LoadBalancer and domain (*.$DOMAIN) DNS records"
execCmd "nslookup myapp.$TDH_INGRESS_CONTOUR_LB_DOMAIN"

ZONE=$(aws route53 list-hosted-zones --query "HostedZones[?starts_with(to_string(Name), '$TDH_ENVNAME.$TDH_DOMAIN.')]" | jq -r '.[].Id' | awk -F'/' '{ print $NF }')
prtHead "Show AWS Route53 Configuration for domain ($TDH_ENVNAME.$TDH_DOMAIN)"
execCmd "aws route53 list-hosted-zones --query \"HostedZones[?starts_with(to_string(Name), '$TDH_ENVNAME.$TDH_DOMAIN.')]\""

prtHead "Show AWS Hosted Zone $TDH_ENVNAME.$TDH_DOMAIN ($ZONE)"
awsResourceRecordText $ZONE
#execCmd "aws route53 list-resource-record-sets --hosted-zone-id $ZONE --output table"
execCmd "kubectl -n tanzu-system-ingress get pods,svc"

prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace $NAMESPACE"

# --- PATCH DEFAULT SERVICE ACCOUNT IN NAMESPACE ---
dockerRateLimit $NAMESPACE > /dev/null 2>&1

prtHead "Create deployment for (my-app-1 and my-app-2) ingress tesing app"
execCmd "kubectl create deployment my-app-1 --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
execCmd "kubectl create deployment my-app-2 --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment my-app-1 --port=8080 -n $NAMESPACE"
execCmd "kubectl expose deployment my-app-2 --port=8080 -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
execCat "/tmp/http-ingress.yaml"
execCmd "kubectl create -f /tmp/http-ingress.yaml"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment by using the DNS Name"
execCmd "curl -s http://myapp1.${DOMAIN}/     # DOMAIN/HOST BASED ROUTING"
execCmd "curl -s http://myapp2.${DOMAIN}/     # DOMAIN/HOST BASED ROUTING"
prtText ""
execCmd "curl -s http://myapp.${DOMAIN}/my-app-1     # CONTEXT BASED ROUTING"
execCmd "curl -s http://myapp.${DOMAIN}/my-app-2     # CONTEXT BASED ROUTING"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
