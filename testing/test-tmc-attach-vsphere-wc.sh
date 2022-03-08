# ############################################################################################
# File: ........: test-tmc-attach-vsphere-wc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Attaching of a TKG Workload Cluster on Azure
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

cd /Users/sdu/workspace/tanzu-demo-hub
. ./functions

CLUSTER=tdh-vsphere-sadubois

stt=$(attachClusterToTMC $CLUSTER attached attached $HOME/.tanzu-demo-hub/config/${CLUSTER}.kubeconfig)
if [ "$stt" != "READY/HEALTHY" ]; then
  echo "ERROR: TKG Worklaod Cluster ($CLUSTER) is currently in state: $stt. TMC Integration can not be"
  echo "       performed right now. Delete the Cluster manually in TMC or wait until it has disapiered and try again"
else 
  echo "Cluster ($CLUSTER) successfully attached"
fi

