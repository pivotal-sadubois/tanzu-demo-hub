# ############################################################################################
# File: ........: test-vshphere-content-library.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Dettaching of a TKG Workload Cluster
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

if [ "$1" == "" ]; then
  echo "Usage: $0 <content-library>"
  exit 1
else
  VSPHERE_CONTENT_LIBRARY=$1
fi

. ../functions
. $HOME/.tanzu-demo-hub.cfg

VSPHERE_DATASTORE=datastore-19           # Hardcoded for H20 Environments
TDH_VSPHERE_API_TOKEN=$(vSphereAPI_getToken "$VSPHERE_TKGS_VCENTER_SERVER" "$VSPHERE_TKGS_VCENTER_ADMIN" "$VSPHERE_TKGS_VCENTER_PASSWORD")

vSphereAPI_createContentLibrary $TDH_VSPHERE_API_TOKEN $VSPHERE_TKGS_VCENTER_SERVER $VSPHERE_CONTENT_LIBRARY $VSPHERE_DATASTORE

