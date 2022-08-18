#!/bin/bash
# ############################################################################################
# File: ........: tap-upload-project-to-gitea.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Create Gitea Organisation and Repostory
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit
export TAP_PROJECT_FILE=$1
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=tkgmc-dev-vsphere-macbook.cfg
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)

[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

if  [ "$TAP_PROJECT_FILE" == "" ]; then 
  echo "Usage: $0 <org> <path/tap-project.zip>"; exit 1
fi

if [ ! -f $TAP_PROJECT_FILE ]; then 
  echo "ERROR: TAP Project not found"; exit 1
fi

