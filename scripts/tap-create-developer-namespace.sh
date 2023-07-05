#!/bin/bash
# ############################################################################################
# File: ........: tap-create-developer-namespace.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDHHOME=$HOME/tanzu-demo-hub
export NAMESPACE=$1

if  [ "$NAMESPACE" == "" ]; then 
  echo "Usage: $0 <namespace>"; exit 1
fi

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# --- VERIFY CLUSTER ACCESS ---
kubectl get ns > /tmp/error.log 2>&1; ret=$?
if [ $ret -ne 0 ]; then
  logMessages /tmp/error.log
  echo "ERROR: Kubernetes cluster not accessabel, please restart tdh-tools container to reinitiate cluster login"
  echo "       => tools/${TDH_TOOLS}.sh"
  exit
fi

# --- CREATE NAMESPACE If IT DOES NOT EXIST ----
[ "$NAMESPACE" != "default" ] && kubectl create ns --dry-run=client -o yaml $NAMESPACE | kubectl apply -f -

# --- CREATE TAP LABEL ---
kubectl label namespaces $NAMESPACE apps.tanzu.vmware.com/tap-ns=""
