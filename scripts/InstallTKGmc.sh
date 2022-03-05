#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGmc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################
# 2021-11-25 ...: fix kind cluster on linux jump host
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=$1
export TDH_TKGMC_NAME_TMP="$2"
export DEBUG="$3"
export TDH_TOOLS_CONTAINER_TYPE="$4"
export DEPLOY_TKG_VERSION="$5"
export NATIVE=0

# --- SETTING FOR TDH-TOOLS ---
export START_COMMAND="$*"
export CMD_EXEC=scripts/$(basename $0)
export CMD_ARGS=$*

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

#############################################################################################################################
################################### EXECUTING CODE WITHIN  TDH-TOOLS DOCKER CONTAINER  ######################################
#############################################################################################################################
runTDHtools $TDH_TOOLS_CONTAINER_TYPE $DEPLOY_TKG_VERSION "Deploy TKG Management Cluster" "$TDHPATH/$CMD_EXEC" "$CMD_ARGS"

# --- VERIFY DEPLOYMENT ---
if [ ! -f ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE} ]; then
  echo "ERROR: Deployment file $DEPLOY_TKG_TEMPLATE can not be found in ${TDHPATH}/deployments"
  exit 1
else
  . ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}
fi

export TDH_DEPLOYMENT_ENV_NAME=$TDH_TKGMC_INFRASTRUCTURE
export TKG_CONFIG=${TDHPATH}/config/$TDH_TKGMC_CONFIG

# --- ACCEPT LICENSE AGREEMENT ---
if [ "${TDH_DEPLOYMENT_ENV_NAME}" == "Azure" ]; then
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot19dot1-ubuntu-1804 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot19dot3-ubuntu-1804 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
  az vm image terms accept --publisher vmware-inc --offer tkg-capi --plan k8s-1dot20dot4-ubuntu-2004 --subscription $AZURE_SUBSCRIPTION_ID > /dev/null 2>&1
fi

# --- RESET TDH_TKGMC_NAME ---
export TDH_TKGMC_NAME="$TDH_TKGMC_NAME_TMP"

#sshEnvironment > /dev/null 2>&1
echo "InstallTKGmc.sh gaga1"
createTKGMCcluster $TDH_TKGMC_NAME; ret=$?
echo "InstallTKGmc.sh gaga1"
if [ $ret -ne 0 ]; then exit 1; fi

return 0
