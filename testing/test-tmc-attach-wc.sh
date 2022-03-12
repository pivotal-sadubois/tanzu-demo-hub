# ############################################################################################
# File: ........: test-tmc-attach-wc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Attaching of a TKG Workload Cluster on Azure
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

if [ "$1" == "" ]; then 
  echo "Usage: $0 <tkg-workload-cluster>"
  exit 1
else
  CLUSTER=$1
fi

cd /Users/sdu/workspace/tanzu-demo-hub
. ./functions

stt=$(attachClusterToTMC $CLUSTER attached attached $HOME/.tanzu-demo-hub/config/${CLUSTER}.kubeconfig)
if [ "$stt" != "READY/HEALTHY" ]; then 
  echo "ERROR: TKG Worklaod Cluster ($CLUSTER) is currently in state: $stt. TMC Integration can not be"
  echo "       performed right now. Delete the Cluster manually in TMC or wait until it has disapiered and try again"
else 
  echo "Cluster ($CLUSTER) successfully attached"
fi
