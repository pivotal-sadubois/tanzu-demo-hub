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
export TDH_TKGMC_NAME_TMP="$1"
export DEBUG="$2"

. $TANZU_DEMO_HUB/functions

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

# --- RESET TDH_TKGMC_NAME ---
export TDH_TKGMC_NAME="$TDH_TKGMC_NAME_TMP"

cnt=$(tanzu cluster list --include-management-cluster 2>/dev/null | grep -c " $$TDH_TKGMC_NAME")
if [ $cnt -gt 0 ]; then
  messageTitle "Deleting Management Cluster ($TDH_TKGMC_NAME)"
  tanzu management-cluster delete ${TDH_TKGMC_NAME -y > /tmp/error.log 2>&1; ret=$?
 
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

  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.kubeconfig ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.kubeconfig
  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.cfg ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.cfg
  [ -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.yaml ] && rm -f $HOME/.tanzu-demo-hub/config/$TDH_TKGMC_NAME-$TDH_USER.yaml
fi

