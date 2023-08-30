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
export SECRET=$2

if  [ "$NAMESPACE" == "" -o "$SECRET" == "" ]; then 
  echo "Usage: $0 <namespace> <secret>"; exit 1
fi

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

kubectl -n $NAMESPACE get secrets $SECRET -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq
