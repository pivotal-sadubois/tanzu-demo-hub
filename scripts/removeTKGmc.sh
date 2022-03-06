#!/bin/bash
# ############################################################################################
# File: ........: removeTKGmc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Delete TKG Management Cluster
# ############################################################################################
# 2021-11-25 ...: fix kind cluster on linux jump host
# ############################################################################################
   
echo removeTKGmc.sh-gaga1
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDH_TKGMC_NAME_TMP="$1"
export DEBUG="$2"
export TDH_TOOLS_CONTAINER_TYPE="$3"
export DEPLOY_TKG_VERSION="$4"
export NATIVE=0

echo removeTKGmc.sh-gaga2
# --- SETTING FOR TDH-TOOLS ---
export START_COMMAND="$*"
export CMD_EXEC=scripts/$(basename $0)
export CMD_ARGS=$*

echo "TDH_TOOLS_CONTAINER_TYPE:$TDH_TOOLS_CONTAINER_TYPE"
echo "DEPLOY_TKG_VERSION:$DEPLOY_TKG_VERSION"

echo "removeTKGmc.sh-gaga3 CMD_EXEC:$CMD_EXEC"
# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
echo removeTKGmc.sh-gaga4

#############################################################################################################################
################################### EXECUTING CODE WITHIN  TDH-TOOLS DOCKER CONTAINER  ######################################
#############################################################################################################################
runTDHtools $TDH_TOOLS_CONTAINER_TYPE $DEPLOY_TKG_VERSION "Delete TKG Management Cluster" "$TDHPATH/$CMD_EXEC" "$CMD_ARGS"

# --- RESET TDH_TKGMC_NAME ---
export TDH_TKGMC_NAME="$TDH_TKGMC_NAME_TMP"

echo removeTKGmc.sh-gaga5
cnt=$(tanzu cluster list --include-management-cluster 2>/dev/null | grep -c " $TDH_TKGMC_NAME")
echo removeTKGmc.sh-gaga5
if [ $cnt -gt 0 ]; then
echo removeTKGmc.sh-gaga6
  messageTitle "Deleting Management Cluster ($TDH_TKGMC_NAME)"
  tanzu management-cluster delete $TDH_TKGMC_NAME -y > /tmp/error.log 2>&1; ret=$?
 
echo removeTKGmc.sh-gaga7
  if [ $ret -ne 0 ]; then
    logMessages /tmp/error.log
    echo "ERROR: failed to delete management cluster ($TDH_TKGMC_NAME)"
      if [ "$NATIVE" == "0" ]; then
    echo "    => tools/tdh-tools.sh"
      echo "       tdh-tools:/$ tanzu management-cluster delete $TDH_TKGMC_NAME -y"
      echo "       tdh-tools:/$ exit"
    else
      echo "    => tanzu management-cluster delete $TDH_TKGMC_NAME -y"
    fi

    exit 1
  fi
echo removeTKGmc.sh-gaga8

  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.kubeconfig ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.kubeconfig
  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.cfg ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.cfg
  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.yaml ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME.yaml
echo removeTKGmc.sh-gaga9
fi

