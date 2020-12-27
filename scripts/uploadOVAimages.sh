#!/bin/bash
# ############################################################################################
# File: ........: uploadOVAimages.sh
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

export GOVC_INSECURE=1
export GOVC_URL=https://${VSPHERE_SERVER}/sdk
export GOVC_USERNAME=$VSPHERE_ADMIN
export GOVC_PASSWORD=$VSPHERE_PASSWORD
export GOVC_DATASTORE=$VSPHERE_DATASTORE
export GOVC_NETWORK="$VSPHERE_MANAGEMENT_NETWORK"
export GOVC_RESOURCE_POOL=/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}/Resources

OVFTOOL="/usr/bin/ovftool --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFTOOL="/usr/bin/ovftool -q --overwrite --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFTOOL="/usr/bin/ovftool -q --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFOPTS="--network=$VSPHERE_MANAGEMENT_NETWORK --datastore=$VSPHERE_DATASTORE"
OVFCONN="vi://${VSPHERE_ADMIN}@${VSPHERE_SERVER}/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}"

# --- TEST GOVC CONNECTION ---
govc vm.info vc01 > /dev/null 2>&1; ret=$?
if [ $ret -ne 0 ]; then 
  echo "ERROR: govc: Connection to vCenter failed:"
  echo "       => govc vm.info vc01"; exit
fi

messageTitle "Uploading OVS Images to vSphere"
for n in $TDH_TKGMC_TKG_IMAGES; do
  pth=$(echo $n | awk -F'/' '{ print $2 }' | sed -e 's/-vmware.1.ova//g' -e 's/+vmware.1.ova//g')
  nam=$(echo $n | awk -F'/' '{ print $2 }')
  cnt=$(govc datastore.ls -ds=$VSPHERE_DATASTORE | grep -c "$pth")
  if [ $cnt -eq 0 ]; then
    stt="uploaded"
    echo "$VSPHERE_PASSWORD" | $OVFTOOL $OVFOPTS tanzu-demo-hub/${n} $OVFCONN > /dev/null 2>&1
    src=$(govc find -name "${pth}*")
    vmn=$(govc find -name "${pth}*" | awk -F'/' '{ print $NF }')
echo "govc vm.clone -template=true -folder=Templates -vm /CoreDC/vm/${vmn} -force=true ${vmn}"
echo "govc vm.destroy /CoreDC/vm/${vmn}"
exit
    govc vm.clone -template=true -vm /CoreDC/vm/${vmn} -folder=Templates ${vmn}

    
govc find -name "photon*"
echo "VM:$vmn"
read x
  else
    stt="already uploaded"
  fi

  messagePrint " - OVA Image: $n"             "$stt"
done

