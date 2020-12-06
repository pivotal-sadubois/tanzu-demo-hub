#!/bin/bash
# ============================================================================================
# File: ........: deploy_tkgmc_azure.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

if [ ! -f /tkg_software_installed ]; then
  echo "ERROR: $0 Needs to run on a TKG Jump Host"; exit
fi

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
echo '                  _____ _  ______   ___                                               '
echo '                 |_   _| |/ / ___| |_ _|_ __   __ _ _ __ ___  ___ ___                 '
echo '                   | | |   / |  _   | ||  _ \ / _  |  __/ _ \/ __/ __|                '
echo '                   | | |   \ |_| |  | || | | | (_| | | |  __/\__ \__ \                '
echo '                   |_| |_|\_\____| |___|_| |_|\__  |_|  \___||___/___/                '
echo '                                              |___/                                   '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '              Contour Ingress Example with Domain and Context based Routing           '
echo '                               by Sacha Dubois, VMware Inc                            '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

TDH_TKGWC_NAME=tdh-1
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
stt=$(tkg get cluster $TDH_TKGWC_NAME --config=$TDHPATH/config/$TDH_TKGMC_CONFIG -o json | jq -r --arg key $TDH_TKGWC_NAME '.[] | select(.name == $key).status') 
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

  DOMAIN="apps-${TDH_TKGWC_NAME}.${TDH_TKGMC_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}"
else
  echo "ERROR: can not find ${TDHPATH}/deployments/$TKG_DEPLOYMENT"; exit
fi

if [ -d ../../certificates ]; then
  TLS_CERTIFICATE=../../certificates/fullchain.pem
  TLS_PRIVATE_KEY=../../certificates/privkey.pem
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

TKG_EXTENSIONS=${TDHPATH}/extensions/tkg-extensions-v1.2.0+vmware.1

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





