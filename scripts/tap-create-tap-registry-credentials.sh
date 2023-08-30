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

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

REGISTRY_USERNAME="admin"
REGISTRY_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
REGISTRY_SERVER=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)

echo "tanzu secret registry add tap-registry \
  --server $REGISTRY_SERVER \
  --username "$REGISTRY_USERNAME" \
  --password "$REGISTRY_PASSWORD" \
  --namespace tap-install --yes \
  --export-to-all-namespaces"
exit

tanzu secret registry add tap-registry \
  --server $REGISTRY_SERVER \
  --username "$REGISTRY_USERNAME" \
  --password "$REGISTRY_PASSWORD" \
  --namespace tap-install --yes \
  --export-to-all-namespaces

exit
