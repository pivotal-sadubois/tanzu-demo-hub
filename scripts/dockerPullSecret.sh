#!/bin/bash
# ############################################################################################
# File: ........: dockerPullSecret.sh
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

dockerPullSecret $NAMESPACE
