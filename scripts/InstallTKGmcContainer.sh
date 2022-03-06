#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGmcContainer.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################
# 2021-11-25 ...: fix kind cluster on linux jump host
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDH_TKGMC_NAME=$1
export TKG_TEMPLATE=$2
export TKG_KUBECONFIG=$3
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

tanzu login --server $TDH_TKGMC_NAME > /dev/null 2>&1
cnt=$(tanzu management-cluster get 2>/dev/null | egrep -c " $TDH_TKGMC_NAME ")
if [ ${cnt} -eq 0 ]; then
  # --- CLEANUP OLD CONFIG ---
  export KUBECONFIG=~/.kube-tkg/config

  kubectl config unset clusters.${TDH_TKGMC_NAME}.log > /dev/null 2>&1
  kubectl config unset contexts.${TDH_TKGMC_NAME}-admin@${TDH_TKGMC_NAME} > /dev/null 2>&1
  kubectl config unset users.${TDH_TKGMC_NAME}-admin > /dev/null 2>&1

  # --- CLEAN OLD MANAGEMENT CLUSTER CONFIG ---
  rm -f ~/.tanzu/config.yaml /tmp/$TDH_TKGMC_NAME.log
  rm -rf /home/ubuntu/.config/tanzu
  cleanKubeconfig           $HOME/.kube/config
  cleanKubeconfig           $HOME/.kube-tkg/config

  # --- DELETE KIND CLUSTER ---
  cnt=$(kind get clusters 2>/dev/null | wc -l | awk '{ print $1 }')
  if [ $cnt -gt 0 ]; then
    id=$(kind get clusters)
    messagePrint " ▪ Manually delete leftover Kind Cluster"        "$id"
    kind delete clusters -all
  fi

  #id=$(az group list | jq -r --arg rg "$TDH_TKGMC_NAME" '.[] | select(.name == $rg).id')
  #if [ "$id" != "" ]; then
  #  messagePrint " ▪ Manually delete leftover Azure Resource Group"        "$TDH_TKGMC_NAME"
  #  az group delete -n $TDH_TKGMC_NAME -y
  #fi

  messagePrint " ▪ Management Cluster Creating"        "This may take up to 15min ..."

  ret=1; cnt=0
  while [ $ret -ne 0 -a $cnt -lt 3 ]; do
    if [ $DEBUG -gt 0 ]; then
      messageLine
      tanzu management-cluster create --file $TKG_TEMPLATE -v 0 -t 2h --log-file=/tmp/$TDH_TKGMC_NAME.log; ret=$?
      messageLine
    else
      tanzu management-cluster create --file $TKG_TEMPLATE -v 0 -t 2h --log-file=/tmp/$TDH_TKGMC_NAME.log > /dev/null 2>&1; ret=$?
    fi
  
    [ $ret -eq 0 ] && break
  
    sleep 30
    let cnt=cnt+1
  done

  cnt=$(tanzu management-cluster get 2>/dev/null | grep -c Error)
  if [ ${ret} -ne 0 -o ${cnt} -gt 0 ]; then
    echo "ERROR: failed to create TKG Management Cluster"
    if [ "$NATIVE" == "0" ]; then
      echo "       => tools/${TDH_TOOLS}.sh"
      echo "          tdh-tools:/$ tanzu management-cluster create --file $TKG_TEMPLATE -v 0 --log-file=/tmp/$TDH_TKGMC_NAME.log"
      echo "          tdh-tools:/$ exit"
    else
      echo "       => tanzu management-cluster create --file $TKG_TEMPLATE -v 0 --log-file=/tmp/$TDH_TKGMC_NAME.log"
    fi
    messageLine
    cat /tmp/$TDH_TKGMC_NAME.log
    messageLine

    exit 1
  fi

  messagePrint " ▪ Management Cluster Creating Completed"    "/tmp/$TDH_TKGMC_NAME.log"
else
  messagePrint " ▪ Management Cluster already installed"    "/tmp/$TDH_TKGMC_NAME.log"
fi

if [ ! -f $TKG_KUBECONFIG ]; then
  tanzu management-cluster kubeconfig get --admin > /dev/null 2>&1
  kubectl config set-cluster $TDH_TKGMC_NAME > /dev/null 2>&1
  kubectl config use-context ${TDH_TKGMC_NAME}-admin@$TDH_TKGMC_NAME > /dev/null 2>&1
  context=$(kubectl config view -o json | jq -r '.contexts[].name' 2>/dev/null)
  tanzu management-cluster kubeconfig get --admin --export-file=${TKG_KUBECONFIG} > /dev/null 2>&1; ret=$?
  if [ ${ret} -ne 0 ]; then
    echo "ERROR: failed to export kubeconfig"
    if [ "$NATIVE" == "0" ]; then
      echo "       => tools/${TDH_TOOLS}.sh"
      echo "          tdh-tools:/$ tanzu management-cluster kubeconfig get --admin --export-file=${TKG_KUBECONFIG}"
      echo "          tdh-tools:/$ exit"
    else
      echo "       => tanzu management-cluster kubeconfig get --admin --export-file=${TKG_KUBECONFIG}"
    fi
    exit 1
  fi
fi

exit 0
