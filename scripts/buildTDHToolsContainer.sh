#!/bin/bash
# ############################################################################################
# File: ........: buildTDHToolsContainer.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Create TDH Tools Container
# ############################################################################################

echo "buildTDHToolsContainer.sh gaga1"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=tkgmc-dev-vsphere-macbook.cfg

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)

export TKG_TYPE=$1
export TKG_RELEASE=$2

echo "buildTDHToolsContainer.sh gaga2"
. $TANZU_DEMO_HUB/functions
echo "buildTDHToolsContainer.sh gaga3"

for rel in $(ls -1 $TDHPATH/files/tdh-tools/tdh-tools-tkg-*.cfg | sed -e 's/^.*tools-tkg-//g' -e 's/\.cfg//g'); do
echo "buildTDHToolsContainer.sh gaga4"
  tdh_tools_build $TKG_TYPE $TKG_RELEASE
done

