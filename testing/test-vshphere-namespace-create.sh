# ############################################################################################
# File: ........: test-vshphere-namespace-create.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Dettaching of a TKG Workload Cluster
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

if [ "$1" == "" ]; then 
  echo "Usage: $0 <vsphere-namespace>"
  exit 1
else
  VSPHERE_NAMESPACE=$1
fi

cd $HOME/workspace/tanzu-demo-hub
. ./functions
. $HOME/.tanzu-demo-hub.cfg

VSPHERE_STORAGE_CLASS=tanzu
TDH_VSPHERE_API_TOKEN=$(vSphereAPI_getToken "$VSPHERE_TKGS_VCENTER_SERVER" "$VSPHERE_TKGS_VCENTER_ADMIN" "$VSPHERE_TKGS_VCENTER_PASSWORD")
echo "TDH_VSPHERE_API_TOKEN:$TDH_VSPHERE_API_TOKEN"

vSphereAPI_createNamespace $TDH_VSPHERE_API_TOKEN $VSPHERE_TKGS_VCENTER_SERVER $VSPHERE_NAMESPACE

