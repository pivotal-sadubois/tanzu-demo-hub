#!/bin/bash
# ############################################################################################
# File: ........: deployTKGmc
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=$1

. $TANZU_DEMO_HUB/functions

# --- VERIFY DEPLOYMENT ---
if [ ! -f ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE} ]; then
  echo "ERROR: Deployment file $DEPLOY_TKG_TEMPLATE can not be found in ${TDHPATH}/deployments"
  exit 1
else
  . ${TDHPATH}/deployments/${DEPLOY_TKG_TEMPLATE}
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

export TDH_DEPLOYMENT_ENV_NAME=$TDH_TKGMC_INFRASTRUCTURE
export TKG_CONFIG=${TDHPATH}/config/$TDH_TKGMC_CONFIG

messageTitle "Uploading OVS Images to vSphere"
for n in $TDH_TKGMC_TKG_IMAGES; do
  messagePrint " - OVA Image: $n"             "completed"
done

#ovftool -q --verifyOnly --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas --network="Management" --datastore="datastore1" /tmp/photon-3-kube-v1.17.13-vmware.1.ova 'vi://administrator@corelab.com:00Penwin$@vc01.corelab.com/CoreDC/host/demoCluster01'

OVFTOOL="ovftool -q --verifyOnly --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFOPTS="--network="$VSPHERE_MANAGEMENT_NETWORK --datastore="$VSPHERE_DATASTORE"
OVFCONN="vi://${VSPHERE_ADMIN}:${VSPHERE_PASSWORD}@${VSPHERE_SERVER}/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}"

echo "OVFCONN:$OVFCONN"

#TDH_TKGMC_TKG_IMAGES









