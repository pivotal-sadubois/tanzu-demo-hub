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
TDH_INGRESS_CONTOUR_LB_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_INGRESS_CONTOUR_LB_IP=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_IP)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
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
execCmd "kubectl get ns"
execCmd "kubectl -n tanzu-system-ingress get pods,svc"

prtHead "Show LoadBalancer and domain (*.$DOMAIN) DNS records"
execCmd "nslookup $TDH_INGRESS_CONTOUR_LB_IP"
execCmd "nslookup myapp.$TDH_INGRESS_CONTOUR_LB_DOMAIN"

ZONE=$(aws route53 list-hosted-zones --query "HostedZones[?starts_with(to_string(Name), '$TDH_ENVNAME.$TDH_DOMAIN.')]" | jq -r '.[].Id' | awk -F'/' '{ print $NF }')
prtHead "Show AWS Route53 Configuration for domain ($TDH_ENVNAME.$TDH_DOMAIN)"
execCmd "aws route53 list-hosted-zones --query \"HostedZones[?starts_with(to_string(Name), '$TDH_ENVNAME.$TDH_DOMAIN.')]\""
execCmd "aws route53 list-resource-record-sets --hosted-zone-id $ZONE --output table"
execCmd "kubectl -n tanzu-system-ingress get pods,svc"

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
#execCmd "cat /tmp/http-ingress.yaml"
execCat "/tmp/http-ingress.yaml"
execCmd "kubectl create -f /tmp/http-ingress.yaml"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     # --- Context Based Routing"
echo "     => curl http://echoserver.${DOMAIN}/foo"
echo "     => curl http://echoserver.${DOMAIN}/bar"
echo ""
echo "     # --- Domain Based Routing"
echo "     => curl http://echoserver1.$DOMAIN"
echo "     => curl http://echoserver2.$DOMAIN"
echo ""

exit
aws route53 list-hosted-zones --query "HostedZones[?starts_with(to_string(Name), 'awstkg.pcfsdu.com.')]" | jq -r '.[].Id' | awk -F'/' '{ print $NF }'
aws route53 list-resource-record-sets --hosted-zone-id Z002760624ZGZ1XCXWHFG --output table
Z002760624ZGZ1XCXWHFG
sdubois@tdh-tools:~/workspace/tanzu-demo-hub/demos/tkg-ingress-contour$ kubectl -n tanzu-system-ingress get pods,svc 
NAME                           READY   STATUS    RESTARTS   AGE
pod/contour-78f78b7854-hwwvh   1/1     Running   0          12h
pod/contour-78f78b7854-npsr7   1/1     Running   0          12h
pod/envoy-2gwjz                2/2     Running   0          12h
pod/envoy-dlq8d                2/2     Running   0          12h
pod/envoy-g65qs                2/2     Running   0          12h

NAME              TYPE           CLUSTER-IP       EXTERNAL-IP                                                                  PORT(S)                      AGE
service/contour   ClusterIP      10.111.214.200   <none>                                                                       8001/TCP                     12h
service/envoy     LoadBalancer   10.98.46.90      abb9b070285304dd48604a3e360753eb-1198773579.eu-central-1.elb.amazonaws.com   80:31065/TCP,443:31949/TCP   12h

kubectl -n tanzu-system-ingress get service/envoy -o json | jq -r '.status.loadBalancer.ingress[].hostname'


