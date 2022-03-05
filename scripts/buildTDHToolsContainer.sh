#!/bin/bash
# ############################################################################################
# File: ........: buildTDHToolsContainer.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Create TDH Tools Container
# ############################################################################################

echo ppppp1
hostname
echo ppppp2
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=tkgmc-dev-vsphere-macbook.cfg

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)

export TKG_TYPE=$1
export TKG_RELEASE=$2

[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

tdh_tools_build $TKG_TYPE $TKG_RELEASE

exit 0
