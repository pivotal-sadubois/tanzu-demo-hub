#!/bin/bash
# ############################################################################################
# File: ........: uploadOVAimages.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export DEPLOY_TKG_TEMPLATE=tkgmc-dev-vsphere-macbook.cfg


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

export GOVC_INSECURE=1
export GOVC_URL=https://${VSPHERE_SERVER}/sdk
export GOVC_USERNAME=$VSPHERE_ADMIN
export GOVC_PASSWORD=$VSPHERE_PASSWORD
export GOVC_DATASTORE=$VSPHERE_DATASTORE
export GOVC_NETWORK="$VSPHERE_MANAGEMENT_NETWORK"
export GOVC_RESOURCE_POOL=/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}/Resources

for n in $(govc find -name "photon*"); do
   govc vm.destroy $n
done

for n in $(govc datastore.ls "photon*"); do
  govc datastore.rm -ds=datastore1 -f $n
done
exit

#govc vm.destroy /CoreDC/vm/photon-3-kube-v1.18.10+vmware.1 2>/dev/null
#govc vm.destroy /CoreDC/vm/photon-3-kube-v1.19.3+vmware.1 2>/dev/null
#govc vm.destroy /CoreDC/vm/photon-3-kube-v1.17.13+vmware.1 2>/dev/null
govc datastore.rm -ds=datastore1 -f photon-3-kube-v1.18.10+vmware.1 > /dev/null 2>&1
govc datastore.rm -ds=datastore1 -f photon-3-kube-v1.19.3+vmware.1 > /dev/null 2>&1
govc datastore.rm -ds=datastore1 -f photon-3-kube-v1.17.13+vmware.1 > /dev/null 2>&1

exit
