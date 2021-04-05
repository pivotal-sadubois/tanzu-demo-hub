#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGmc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=$1

echo ggaga1
. $TANZU_DEMO_HUB/functions
echo ggaga2

# --- VERIFY DEPLOYMENT ---
if [ ! -f ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE} ]; then
  echo "ERROR: Deployment file $DEPLOY_TKG_TEMPLATE can not be found in ${TDHPATH}/deployments"
  exit 1
else
  . ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}
fi
echo ggaga3

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi
echo ggaga4

export TDH_DEPLOYMENT_ENV_NAME=$TDH_TKGMC_INFRASTRUCTURE
export TKG_CONFIG=${TDHPATH}/config/$TDH_TKGMC_CONFIG

# --- ACCEPT LICENSE AGREEMENT ---
if [ "${TDH_DEPLOYMENT_ENV_NAME}" == "Azure" ]; then
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot19dot1-ubuntu-1804 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot19dot3-ubuntu-1804 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot20dot4-ubuntu-2004 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
fi
echo ggaga5

sshEnvironment > /dev/null 2>&1
echo ggaga6
createCluster 


