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
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

#############################################################################################################################
################################### EXECUTING CODE WITHIN  TDH-TOOLS DOCKER CONTAINER  ######################################
#############################################################################################################################
runTDHtools $TDH_TOOLS_CONTAINER_TYPE $DEPLOY_TKG_VERSION "Deploy TKG Management Cluster" "$TDHPATH/$CMD_EXEC" "$CMD_ARGS"


hostname
exit

# --- VERIFY DEPLOYMENT ---
if [ ! -f ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE} ]; then
  echo "ERROR: Deployment file $DEPLOY_TKG_TEMPLATE can not be found in ${TDHPATH}/deployments"
  exit 1
else
  . ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
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

# --- CORRECT PERMISSONS ---
[ -d $HOME/.tanzu ] && sudo chown -R ubuntu:ubuntu $HOME/.tanzu
[ -d $HOME/.local ] && sudo chown -R ubuntu:ubuntu $HOME/.local
[ -d $HOME/.config ] && sudo chown -R ubuntu:ubuntu $HOME/.config
[ -d $HOME/.cache ] && sudo chown -R ubuntu:ubuntu $HOME/.cache
[ -d $HOME/.kube-tkg ] && sudo chown -R ubuntu:ubuntu $HOME/.kube-tkg

# --- FIX FOR KIND (https://kb.vmware.com/s/article/85245)
sudo sysctl net/netfilter/nf_conntrack_max=131072 > /dev/null 2>&1

#sshEnvironment > /dev/null 2>&1
createTKGMCcluster $TDH_TKGMC_NAME
if [ $? -ne 0 ]; then exit 1; fi


