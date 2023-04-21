#!/bin/bash
# ############################################################################################
# File: ........: tap-global-registry-secret.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDHHOME=$HOME/tanzu-demo-hub

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg


INSTALL_REGISTRY_HOSTNAME=$(getConfigMap tanzu-demo-hub TDH_SERVICE_REGISTRY_HARBOR)
INSTALL_REGISTRY_USERNAME="admin"
INSTALL_REGISTRY_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)

tanzu secret registry add tap-registry \
    --username ${INSTALL_REGISTRY_USERNAME} \
    --password $INSTALL_REGISTRY_PASSWORD \
    --server ${INSTALL_REGISTRY_HOSTNAME} \
    --export-to-all-namespaces --yes --namespace tap-install
