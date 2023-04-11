#!/bin/bash
# ############################################################################################
# File: ........: vmwarePullSecret.sh
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

kubectl -n $NAMESPACE create secret docker-registry regsecret \
            --docker-server=https://registry.tanzu.vmware.com/ \
            --docker-username=$TDH_REGISTRY_VMWARE_USER \
            --docker-password=$TDH_REGISTRY_VMWARE_PASS 

