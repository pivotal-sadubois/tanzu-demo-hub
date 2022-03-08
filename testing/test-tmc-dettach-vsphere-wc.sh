# ############################################################################################
# File: ........: test-tmc-dettach-vsphere-wc.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test TMC Dettaching of a TKG Workload Cluster on vSphere
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

cd /Users/sdu/workspace/tanzu-demo-hub
. ./functions

CLUSTER=tdh-vsphere-sadubois

detachClusterFromTMConFailure $CLUSTER attached attached force
