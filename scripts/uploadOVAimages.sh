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

export VMWUSER="$TDH_MYVMWARE_USER"
export VMWPASS="$TDH_MYVMWARE_PASS"

cnt=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>&1 | grep -c "ERROR")
if [ $cnt -ne 0 ]; then
  echo "ERROR: failed to login to vmw-cli, please make sure that the environment variables"
  echo "       TDH_MYVMWARE_USER and TDH_MYVMWARE_PASS are set correctly. Please try manually"
  messageLine
  echo "       => . ~/.tanzu-demo-hub.cfg"
  echo "       => export VMWUSER=\$TDH_MYVMWARE_USER"
  echo "       => export VMWPASS=\$TDH_MYVMWARE_PASS"
  echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
  messageLine
  exit
fi

messageTitle "Verify Software Downloads from http://my.vmware.com"
vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1

cnt=0
vmwlist=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^photon" | awk '{ print $1 }')
while [ "$vmwlist" == "" -a $cnt -lt 5 ]; do
  vmwlist=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^photon" | awk '{ print $1 }')
  let cnt=cnt+1
  sleep 10
done

id

for file in $vmwlist; do
  if [ ! -f $TDHPATH/software/$file ]; then
    messagePrint " ▪ Download Photon Image:"                        "$file"

    cnt=0
    while [ ! -f "$vmwfile" -a $cnt -lt 10 ]; do
      vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1
      vmw-cli cp $vmwfile > /tmp/log 2>&1
      let cnt=cnt+1
      sleep 60
    done

    if [ ! -f $file ]; then
      echo "ERROR: failed to download $file, after $cnt atempts"
      echo "       => export VMWUSER=\"$TDH_MYVMWARE_USER\""
      echo "       => export VMWPASS=\"$TDH_MYVMWARE_PASS\""
      echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
      echo "       => vmw-cli cp $file"
      messageLine
      cat /tmp/log
      messageLine
      exit 1
    else
      mv $file $TDHPATH/software
    fi
  fi
done

exit

# --- TEST GOVC CONNECTION ---
govc vm.info $(echo $VSPHERE_SERVER | awk -F. '{ print $1 }') > /dev/null 2>&1; ret=$?
if [ $ret -ne 0 ]; then 
  echo "1 ERROR: govc: Connection to vCenter failed:"
  echo "       => govc vm.info $(echo $VSPHERE_SERVER | awk -F. '{ print $1 }')"; exit
fi

messageTitle "Uploading OVS Images to vSphere"
for n in $TDH_TKGMC_TKG_IMAGES; do
  pth=$(echo $n | awk -F'/' '{ print $2 }' | sed -e 's/-vmware.[0-9].ova//g' -e 's/+vmware.[0-9].ova//g')
  nam=$(echo $n | awk -F'/' '{ print $2 }')
  cnt=$(govc datastore.ls -ds=$VSPHERE_DATASTORE | grep -c "$pth")
  if [ $cnt -eq 0 ]; then
    stt="uploaded"
    echo "$VSPHERE_PASSWORD" | $OVFTOOL $OVFOPTS tanzu-demo-hub/${n} $OVFCONN > /dev/null 2>&1
    src=$(govc find -name "${pth}*")
    vmn=$(govc find -name "${pth}*" | awk -F'/' '{ print $NF }')
    govc vm.clone -template=true -vm /CoreDC/vm/${vmn} -folder=Templates -force=true ${vmn} > /dev/null 2>&1
    govc vm.destroy /CoreDC/vm/${vmn}
  else
    stt="already uploaded"
  fi

  messagePrint " - OVA Image: $n"             "$stt"
done

