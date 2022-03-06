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
export CONFIG_FILE=$1
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

echo "tanzu management-cluster create --file $CONFIG_FILE -v 0 -t 2h"
tanzu management-cluster create --file $CONFIG_FILE -v 0 -t 2h

tanzu management-cluster get > /dev/null 2>&1; ret=$?
[ $ret -eq 0 ] && return 0 || return 1

