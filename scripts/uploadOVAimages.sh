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

if [ "${TDH_TKGMC_TKG_TYPE}" == "tkgs" ]; then
  VSPHERE_DNS_DOMAIN="$VSPHERE_TKGS_DNS_DOMAIN"
  VSPHERE_API_SERVER="$VSPHERE_TKGS_API_SERVER"
  VSPHERE_VCENTER_SERVER="$VSPHERE_TKGS_VCENTER_SERVER"
  VSPHERE_VCENTER_ADMIN="$VSPHERE_TKGS_VCENTER_ADMIN"
  VSPHERE_VCENTER_PASSWORD="$VSPHERE_TKGS_VCENTER_PASSWORD"
  VSPHERE_JUMPHOST_NAME="$VSPHERE_TKGS_JUMPHOST_NAME"
  VSPHERE_JUMPHOST_USER="$VSPHERE_TKGS_JUMPHOST_USER"
  VSPHERE_JUMPHOST_PASSWORD="$VSPHERE_TKGS_JUMPHOST_PASSWORD"
  VSPHERE_SSH_PRIVATE_KEY_FILE="$VSPHERE_TKGS_SSH_PRIVATE_KEY_FILE"
  VSPHERE_SSH_PUBLIC_KEY_FILE="$VSPHERE_TKGS_SSH_PUBLIC_KEY_FILE"
  VSPHERE_DATASTORE="$VSPHERE_TKGS_DATASTORE"
  VSPHERE_DATACENTER="$VSPHERE_TKGS_DATACENTER"
  VSPHERE_CLUSTER="$VSPHERE_TKGS_CLUSTER"
  VSPHERE_NETWORK="$VSPHERE_TKGS_NETWORK"
else
  VSPHERE_DNS_DOMAIN="$VSPHERE_TKGM_DNS_DOMAIN"
  VSPHERE_API_SERVER="$VSPHERE_TKGM_API_SERVER"
  VSPHERE_VCENTER_SERVER="$VSPHERE_TKGM_VCENTER_SERVER"
  VSPHERE_VCENTER_ADMIN="$VSPHERE_TKGM_VCENTER_ADMIN"
  VSPHERE_VCENTER_PASSWORD="$VSPHERE_TKGM_VCENTER_PASSWORD"
  VSPHERE_JUMPHOST_NAME="$VSPHERE_TKGM_JUMPHOST_NAME"
  VSPHERE_JUMPHOST_USER="$VSPHERE_TKGM_JUMPHOST_USER"
  VSPHERE_JUMPHOST_PASSWORD="$VSPHERE_TKGM_JUMPHOST_PASSWORD"
  VSPHERE_SSH_PRIVATE_KEY_FILE="$VSPHERE_TKGM_SSH_PRIVATE_KEY_FILE"
  VSPHERE_SSH_PUBLIC_KEY_FILE="$VSPHERE_TKGM_SSH_PUBLIC_KEY_FILE"
  VSPHERE_DATASTORE="$VSPHERE_TKGM_DATASTORE"
  VSPHERE_DATACENTER="$VSPHERE_TKGM_DATACENTER"
  VSPHERE_CLUSTER="$VSPHERE_TKGM_CLUSTER"
  VSPHERE_NETWORK="$VSPHERE_TKGM_NETWORK"
fi

export TDH_DEPLOYMENT_ENV_NAME=$TDH_TKGMC_INFRASTRUCTURE
export TKG_CONFIG=${TDHPATH}/config/$TDH_TKGMC_CONFIG

export GOVC_INSECURE=1
export GOVC_URL=https://${VSPHERE_VCENTER_SERVER}/sdk
export GOVC_USERNAME=$VSPHERE_VCENTER_ADMIN
export GOVC_PASSWORD=$VSPHERE_VCENTER_PASSWORD
export GOVC_DATASTORE=$VSPHERE_DATASTORE
export GOVC_NETWORK="$VSPHERE_NETWORK"
export GOVC_RESOURCE_POOL=/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}/Resources

echo "export GOVC_INSECURE=1 XXX"
echo "export GOVC_URL=https://${VSPHERE_VCENTER_SERVER}/sdk"
echo "export GOVC_USERNAME=$VSPHERE_VCENTER_ADMIN"
echo "export GOVC_PASSWORD=$VSPHERE_VCENTER_PASSWORD"
echo "export GOVC_DATASTORE=$VSPHERE_DATASTORE"
echo "export GOVC_NETWORK="$VSPHERE_NETWORK""
echo "export GOVC_RESOURCE_POOL=/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}/Resources"

OVFTOOL="/usr/bin/ovftool --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFTOOL="/usr/bin/ovftool -q --overwrite --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFTOOL="/usr/bin/ovftool -q --skipManifestCheck --noDestinationSSLVerify --noSourceSSLVerify --acceptAllEulas"
OVFOPTS="--network=\"$VSPHERE_NETWORK\" --datastore=\"$VSPHERE_DATASTORE\""
OVFCONN="vi://${VSPHERE_VCENTER_ADMIN}@${VSPHERE_VCENTER_SERVER}/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}"

echo "OVFCONN:$OVFCONN"
echo "OVFTOOL:$OVFTOOL"

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

for file in $vmwlist; do
  if [ ! -f $TDHPATH/software/$file ]; then
    messagePrint " ▪ Download Photon Image:"                        "$file"

    cnt=0
    while [ ! -f "$file" -a $cnt -lt 10 ]; do
      vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1
      vmw-cli cp $file > /tmp/log 2>&1
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

# --- TEST GOVC CONNECTION ---
govc vm.info $(echo $VSPHERE_VCENTER_SERVER | awk -F. '{ print $1 }') > /dev/null 2>&1; ret=$?
if [ $ret -ne 0 ]; then 
  echo "1 ERROR: govc: Connection to vCenter failed 2:"
  echo "       => govc vm.info $(echo $VSPHERE_VCENTER_SERVER | awk -F. '{ print $1 }')"; exit
fi

messageTitle "Uploading OVS Images to vSphere"
echo "TDH_TKGMC_TKG_IMAGES:$TDH_TKGMC_TKG_IMAGES"

TDH_TKGMC_TKG_IMAGES=$(ls -1 $TDHPATH/software/phot* | awk -F'/' '{ print $NF }') 
for n in $TDH_TKGMC_TKG_IMAGES; do
  tmp=$(echo $n | sed -e 's/-tkg.*.ova//g')
  nam=$(echo $tmp | sed -e 's/-vmware.*$//g' -e 's/+vmware.*$//g') 
  ver=$(echo $tmp | sed -e 's/^.*-\(vmware.*\)$/\1/g' -e 's/^.*+\(vmware.*\)$/\1/g')
  cnt=$(govc datastore.ls -ds=$VSPHERE_DATASTORE | grep -c "$nam")

  if [ $cnt -eq 0 ]; then
    stt="uploaded"
    cnt=0; ret=1
    while [ $ret -ne 0 -a $cnt -lt 5 ]; do
      #echo $VSPHERE_VCENTER_PASSWORD | $OVFTOOL $OVFOPTS "tanzu-demo-hub/software/${n}" $OVFCONN > /tmp/log 2>&1; ret=$?

      echo $VSPHERE_VCENTER_PASSWORD | /usr/bin/ovftool -q --overwrite --skipManifestCheck --noDestinationSSLVerify \
          --noSourceSSLVerify --acceptAllEulas --network="$VSPHERE_NETWORK" --datastore="$VSPHERE_DATASTORE" \
          "tanzu-demo-hub/software/${n}" \
          "vi://${VSPHERE_VCENTER_ADMIN}@${VSPHERE_VCENTER_SERVER}/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}"; ret=$?

echo "vi://${VSPHERE_VCENTER_ADMIN}@${VSPHERE_VCENTER_SERVER}/${VSPHERE_DATACENTER}/host/${VSPHERE_CLUSTER}"
      let cnt=cnt+1
      sleep 30
    done

    # --- CLEANUP ---
    rm -f nohup

    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to upload image: $n after $cnt attempts"
      echo "       => echo $VSPHERE_VCENTER_PASSWORD | $OVFTOOL $OVFOPTS tanzu-demo-hub/software/${n} $OVFCONN"
      messageLine; cat /tmp/log; messageLine
      exit
    fi

    src=$(govc find -name "${nam}*" | tail -1)
    vmn=$(govc find -name "${nam}*" | tail -1 | awk -F'/' '{ print $NF }')
echo "SRC:$src"
echo "vMN:$vmn"
    #govc vm.clone -template=true -vm /${VSPHERE_DATACENTER}/vm/${vmn} -folder=Templates -force=true ${vmn} > /dev/null 2>&1
echo "govc vm.clone -template=true -vm /${VSPHERE_DATACENTER}/vm/${vmn} -folder=Templates -force=true ${vmn}"
    #govc vm.clone -template=true -vm /${VSPHERE_DATACENTER}/vm/${vmn} -folder=Templates -force=true ${vmn} 
    govc vm.clone -template=true -vm /${VSPHERE_DATACENTER}/vm/${vmn} -force=true ${vmn} 
echo gaga1
echo "govc vm.destroy /${VSPHERE_DATACENTER}/vm/${vmn}"
    govc vm.destroy /${VSPHERE_DATACENTER}/vm/${vmn}
  else
    stt="already uploaded"
  fi
#pth

  messagePrint " - OVA Image: $n"             "$stt"
done

# KUBECTL_VSPHERE_PASSWORD
# kubectl vsphere login --insecure-skip-tls-verify --server wcp.haas-513.pez.vmware.com -u administrator@vsphere.local o

