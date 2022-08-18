#!/bin/bash
# ############################################################################################
# File: ........: tap-create-gitea-repository.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Create Gitea Organisation and Repostory
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit
export GITEA_ORGANIZATION=$1
export GITEA_REPOSITORY=$2
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=tkgmc-dev-vsphere-macbook.cfg
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)

if  [ "$GITEA_ORGANIZATION" == "" ]; then 
  echo "Usage: $0 <org> <repository"; exit 1
fi

if  [ "$GITEA_ORGANIZATION" == "" -o "$GITEA_REPOSITORY" == "" ]; then
  echo "Usage: $0 <gitea-organisatino> <gitea-repository>"
  exit 1
else
  GITEA_ORGANISATION=$1
  GITEA_REPOSITORY=$2
fi


[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

createGiteaOrg  $GITEA_ORGANISATION
echo "gitea/organisation/$GITEA_ORGANISATION configured"
createGiteaRepo $GITEA_ORGANISATION $GITEA_REPOSITORY
echo "gitea/repository/$GITEA_REPOSITORY configured"
