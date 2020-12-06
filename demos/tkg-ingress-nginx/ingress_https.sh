# ============================================================================================
# File: ........: ingress_https.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Monitoring with Grafana and Prometheus Demo
# ============================================================================================

f [ ! -f /tkg_software_installed ]; then
  echo "ERROR: $0 Needs to run on a TKG Jump Host"; exit
fi

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="tkg-ingress-nginx"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

 Created by /usr/local/bin/figlet
clear
echo '                  _____ _  ______   ___                                               '
echo '                 |_   _| |/ / ___| |_ _|_ __   __ _ _ __ ___  ___ ___                 '
echo '                   | | |   / |  _   | ||  _ \ / _  |  __/ _ \/ __/ __|                '
echo '                   | | |   \ |_| |  | || | | | (_| | | |  __/\__ \__ \                '
echo '                   |_| |_|\_\____| |___|_| |_|\__  |_|  \___||___/___/                '
echo '                                              |___/                                   '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '              NGINX Ingress Example with Domain and Context based Routing             '
echo '                               by Sacha Dubois, VMware Inc                            '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

if [ -f $TDHPATH/config/${TDH_TKGWC_NAME}.cfg ]; then
  . $TDHPATH/config/${TDH_TKGWC_NAME}.cfg
else
  echo "ERROR: $TDHPATH/config/${TDH_TKGWC_NAME}.cfg not found"; exit
fi

K8S_CONTEXT_CURRENT=$(kubectl config current-context)
if [ "${K8S_CONTEXT_CURRENT}" != "${K8S_CONTEXT}" ]; then
  kubectl config use-context $K8S_CONTEXT
fi

# --- CHECK CLUSTER ---
stt=$(tkg get cluster $TDH_TKGWC_NAME --config=$TDHPATH/config/$TDH_TKGMC_CONFIG -o json | jq -r '.[].status')
if [ "${stt}" != "running" ]; then
  echo "ERROR: tkg cluster is not in 'running' status"
  echo "       => tkg get cluster $TDH_TKGWC_NAME --config=$TDHPATH/config/$TDH_TKGMC_CONFIG"; exit
fi

kubectl get namespace $NAMESPACE > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ERROR: Namespace '$NAMESPACE' already exist"
  echo "       => kubectl delete namespace $NAMESPACE"
  exit 1
fi

if [ -f ${TDHPATH}/deployments/$TKG_DEPLOYMENT ]; then
  . ${TDHPATH}/deployments/$TKG_DEPLOYMENT

  DOMAIN="nginx-${TDH_TKGWC_NAME}.${TDH_TKGMC_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}"
else
  echo "ERROR: can not find ${TDHPATH}/deployments/$TKG_DEPLOYMENT"; exit
fi

if [ -d ../../certificates/$dom -a "$dom" != "" ]; then 
  TLS_CERTIFICATE=../../certificates/$dom/fullchain.pem 
  TLS_PRIVATE_KEY=../../certificates/$dom/privkey.pem 
fi

# --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then 
  echo ""
  echo "ERROR: Certificate and Private-Key has not been specified. Please set"
  echo "       the following environment variables:"
  echo "       => export TLS_CERTIFICATE=<cert.pem>"
  echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
  echo ""
  exit 1 
else
  verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
fi

# --- CONVERT CERTS TO BASE64 ---
cert=$(base64 --wrap=10000 $TLS_CERTIFICATE) 
pkey=$(base64 --wrap=10000 $TLS_PRIVATE_KEY) 

# --- GENERATE INGRES FILES ---
cat files/https-secret.yaml | sed -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/https-secret.yaml
echo "  tls.crt: \"$cert\"" >> /tmp/https-secret.yaml
echo "  tls.key: \"$pkey\"" >> /tmp/https-secret.yaml

# --- PREPARATION ---
cat files/https-ingress.yaml | sed -e "s/DNS_DOMAIN/$DOMAIN/g" -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/https-ingress.yaml

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

prtHead "Create a secret with the certificates of domain $DOMAIN"
execCmd "cat /tmp/https-secret.yaml"
execCmd "kubectl create -f /tmp/https-secret.yaml -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
execCmd "cat /tmp/https-ingress.yaml"
execCmd "kubectl create -f /tmp/https-ingress.yaml -n $NAMESPACE"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     # --- Context Based Routing"
echo "     => curl https://echoserver.${DOMAIN}/foo"
echo "     => curl https://echoserver.${DOMAIN}/bar"
echo ""
echo "     # --- Domain Based Routing"
echo "     => curl https://echoserver1.$DOMAIN"
echo "     => curl https://echoserver2.$DOMAIN"
echo ""



exit










prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace cheese"

prtHead "Create the deployment for stilton-cheese"
execCmd "kubectl create deployment stilton-cheese --image=errm/cheese:stilton -n cheese"

prtHead "Create the deployment for stilton-cheese"
execCmd "kubectl create deployment cheddar-cheese --image=errm/cheese:cheddar -n cheese"

prtHead "Verify Deployment for stilton and cheddar cheese"
execCmd "kubectl get deployment,pods -n cheese"

prtHead "Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment stilton-cheese --type=NodePort --port=80 -n cheese"

prtHead "Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment cheddar-cheese --type=NodePort --port=80 -n cheese"

prtHead "Verify services of cheddar-cheese and stilton-cheese"
execCmd "kubectl get svc -n cheese"

prtHead "Describe services cheddar-cheese and stilton-cheese"
execCmd "kubectl describe svc cheddar-cheese -n cheese"
execCmd "kubectl describe svc stilton-cheese -n cheese"

prtHead "Review ingress configuration file (/tmp/cheese-ingress_tls.yml)"
execCmd "more /tmp/cheese-ingress_tls.yml"

prtHead "Create ingress routing cheddar-cheese and stilton-cheese service"
execCmd "kubectl create -f /tmp/cheese-ingress_tls.yml -n cheese"
execCmd "kubectl get ingress -n cheese"
execCmd "kubectl describe ingress -n cheese"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://cheddar-cheese.$PKS_APPATH"
echo "     => https://stilton-cheese.$PKS_APPATH"
echo ""

exit 0
