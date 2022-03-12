# ############################################################################################
# File: ........: test-tmc-dettach-wc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Dettaching of a TKG Workload Cluster
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

detachClusterFromTMConFailure $CLUSTER attached attached force
