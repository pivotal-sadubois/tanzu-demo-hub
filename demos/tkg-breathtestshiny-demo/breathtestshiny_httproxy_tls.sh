#!/bin/bash
# ============================================================================================
# File: ........: deploy_tkgmc_azure.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
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
echo '                          Breath Test Shiny - Demo Application                        '
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

# --- DUMP TLS CERT FROM SECRET ---
kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.crt"' | base64 -d > /tmp/tanzu-demo-hub-crt.pem
kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.key"' | base64 -d > /tmp/tanzu-demo-hub-key.pem
TLS_CERTIFICATE=/tmp/tanzu-demo-hub-crt.pem
TLS_PRIVATE_KEY=/tmp/tanzu-demo-hub-key.pem

# --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then
  echo ""
  echo "ERROR: Certificate and Private-Key has not been specified. Please set"
  echo "       the following environment variables:"
  echo "       => export TLS_CERTIFICATE=<cert.pem>"
  echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
  echo ""
  exit 1
#else
#  verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
fi

# --- CONVERT CERTS TO BASE64 ---
if [ "$(uname)" == "Darwin" ]; then 
  cert=$(base64 $TLS_CERTIFICATE)
  pkey=$(base64 $TLS_PRIVATE_KEY)
else
  cert=$(base64 --wrap=10000 $TLS_CERTIFICATE)
  pkey=$(base64 --wrap=10000 $TLS_PRIVATE_KEY)
fi

# --- GENERATE INGRES FILES ---
cat files/https-secret.yaml | sed -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/https-secret.yaml
echo "  tls.crt: \"$cert\"" >> /tmp/https-secret.yaml
echo "  tls.key: \"$pkey\"" >> /tmp/https-secret.yaml

TKG_EXTENSIONS=${TDHPATH}/extensions/tkg-extensions-v1.2.0+vmware.1

# --- PREPARATION ---
cat files/httproxy.yaml | sed -e "s/DNS_DOMAIN/$DOMAIN/g" -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/httproxy.yaml

prtHead "Create seperate namespace to host the $APPNAME Demo"
execCmd "kubectl create namespace $NAMESPACE"
dockerPullSecret $NAMESPACE > /dev/null 2>&1

prtHead "Create deployment for the HTTPproxy tesing app"
execCmd "kubectl create deployment $APPNAME --image=dmenne/breathtestshiny --port=3838 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment breathtestshiny --port=3838 -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Create a secret with the certificates of domain $DOMAIN"
execCat "/tmp/https-secret.yaml"
echo "kubectl create -f /tmp/https-secret.yaml -n $NAMESPACE"
execCmd "kubectl create -f /tmp/https-secret.yaml -n $NAMESPACE"

prtHead "Create the HTTPproxy with context based routing"
execCat "/tmp/httproxy.yaml"
execCmd "kubectl create -f /tmp/httproxy.yaml -n $NAMESPACE"
execCmd "kubectl get httproxy,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     # --- Context Based Routing"
echo "     => https://$APPNAME.${DOMAIN}/"
echo ""

exit

