#!/bin/bash
# ############################################################################################
# File: ........: deployTKGmc
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=$1

echo "DEPLOY_TKG_TEMPLATE:$DEPLOY_TKG_TEMPLATE"
echo "TANZU_DEMO_HUB:$TANZU_DEMO_HUB"
echo "TDHPATH:$TDHPATH"

. $TANZU_DEMO_HUB/functions

# --- VERIFY DEPLOYMENT ---
if [ ! -f ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE} ]; then
  echo "ERROR: Deployment file $DEPLOY_TKG_TEMPLATE can not be found in ${TDHPATH}/deployments"
  exit 1
else
  . ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}

echo "222 TDH_TKGMC_CONFIG:$TDH_TKGMC_CONFIG"
echo ". ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}"
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

export TDH_DEPLOYMENT_ENV_NAME=$TDH_TKGMC_INFRASTRUCTURE
export TKG_CONFIG=${TDHPATH}/config/$TDH_TKGMC_CONFIG

echo "TDH_TKGMC_INFRASTRUCTURE:$TDH_TKGMC_INFRASTRUCTURE"
echo "TDH_DEPLOYMENT_ENV_NAME:$TDH_DEPLOYMENT_ENV_NAME"
echo "TKG_CONFIG:$TKG_CONFIG"

exit

createCluster 

