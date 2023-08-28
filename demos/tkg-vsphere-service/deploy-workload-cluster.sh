#!/bin/bash
# ============================================================================================
# File: ........: deploy-workload-cluster.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Workload Cluster on vSphere
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDH_DEMO_DIR="tkg-vsphere-service"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tkg-vsphere-service"
export GUEST_CLUSTER=tkg-cluster-1
export TDHV2_LIST_DEPLOYMENTS=0

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TDHHOME/functions ] &&  . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

usage() {
  echo ""
  echo "USAGE: $0 [options] -e <deploy-environment>"
  echo ""
}

while [ "$1" != "" ]; do
  case $1 in
    -e)            TDHV2_DEPLOY_ENVIRONMENT=$2;;
  esac
  shift
done

[ "${TDHV2_DEPLOY_ENVIRONMENT}" == "" ] && listTDHenv && usage && exit 0
[ -f $HOME/.tanzu-demo-hub/config/${TDHV2_DEPLOY_ENVIRONMENT}.cfg ] && . $HOME/.tanzu-demo-hub/config/${TDHV2_DEPLOY_ENVIRONMENT}.cfg

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '           _____ _  ______    __                     ____        _                    '
echo '          |_   _| |/ / ___|  / _| ___  _ __  __   __/ ___| _ __ | |__   ___ _ __ ___  '
echo '            | | |   / |  _  | |_ / _ \|  __| \ \ / /\___ \|  _ \|  _ \ / _ \  __/ _ \ '
echo '            | | | . \ |_| | |  _| (_) | |     \ V /  ___) | |_) | | | |  __/ | |  __/ '
echo '            |_| |_|\_\____| |_|  \___/|_|      \_/  |____/| .__/|_| |_|\___|_|  \___| '
echo '                                                          |_|                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '               VMware vSphere for Tanzu Service - TKG Workload Cluster deployment     '  
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- VERIFY SUPERVISOR CLUSTER LOGIN --- 
[ ! -f $HOME/.kube/config ] && touch $HOME/.kube/config
export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: can not login to vSphere Supervisor Cluster: $TDH_TKGMC_SUPERVISORCLUSTER"
fi

# --- SET ENVIRONMENT ---
[ "$VSPHERE_NAMESPACE" == "" ] && export VSPHERE_NAMESPACE=tanzu-demo-hub

# --- CLEANUP ---
cmdLoop kubectl config use-context $TDH_TKGMC_SUPERVISORCLUSTER > /dev/null 2>&1
cmdLoop kubectl get tanzukubernetescluster -n $VSPHERE_NAMESPACE -o json > /tmp/output.json 
nam=$(jq -r --arg key "$GUEST_CLUSTER" '.items[] | select(.metadata.name == $key).metadata.name' /tmp/output.json)
if [ "$nam" == "$GUEST_CLUSTER" ]; then 
  echo " INFO: Deleting leftover TKG Cluster ($GUEST_CLUSTER) from previous demo. This"
  echo "       may take a couple of minues."
  echo ""
  cmdLoop kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER --wait=true > /dev/null 2>&1
fi

prtHead "Login to the vSphere Envifonment on ($TDH_TKGMC_VSPHERE_SERVER / $TDH_TKGMC_VSPHERE_USER)" 
prtText " - inspect 'Hosts and Clusters'"
prtText " - inspect 'Workload Management'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Create a new vSphere Namespace '$VSPHERE_NAMESPACE'"
prtText " - Menu -> 'Workload Management' => New Namespace"
prtText "      - Name: $VSPHERE_NAMESPACE => Create"
prtText " - Namespace -> '$VSPHERE_NAMESPACE' -> Summary"
#prtText "      - Storage -> Add Storage -> $VSPHERE_TKGS_SUPERVISOR_STORAGE_POLICPOLICY"
prtText "      - Storage -> Add Storage -> $VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS"
prtText "      - Permissions"
prtText "      - Capacity and Usage"
prtText "      - VM Servic -> Add VM Class"
prtText "           best-effort-medium, guaranteed-medium"
prtText ""
prtText "press 'return' to continue"; read x


prtHead "Login to the vSphere Supervisor Cluster ($TDH_TKGMC_SUPERVISORCLUSTER) and set Environment and Context"
execCmd "kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER"
#execCmd "kubectl config get-contexts"
#execCmd "kubectl config get-clusters"
execCmd "kubectl config use-context $TDH_TKGMC_SUPERVISORCLUSTER"

cat files/tkg-cluster-1.yaml| sed "s/VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS/$VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS/g" > /tmp/tkg-cluster-1.yaml

prtHead "Create a Kubernetes Cluster Config ($GUEST_CLUSTER)"
execCmd "kubectl get tanzukubernetesreleases"
execCat "/tmp/tkg-cluster-1.yaml"

execCmd "kubectl apply -f /tmp/tkg-cluster-1.yaml --wait=true"
execCmd "kubectl get tanzukubernetescluster -n $VSPHERE_NAMESPACE"

stt=""
while [ "$stt" != "True" ]; do
  stt=$(kubectl get clusters -n $VSPHERE_NAMESPACE -o json 2>/dev/null | \
   jq -r --arg key "$GUEST_CLUSTER" '.items[] | select(.metadata.name == $key).status.conditions[] | select(.type == "Ready").status' 2>/dev/null)
  sleep 10
done

execCmd "kubectl get clusters --all-namespaces"

prtHead "Access the kubernetes cluster ($GUEST_CLUSTER)"
execCmd "kubectl vsphere login \\
          --tanzu-kubernetes-cluster-name $GUEST_CLUSTER \\
          --tanzu-kubernetes-cluster-namespace $VSPHERE_NAMESPACE \\
          --server $TDH_TKGMC_SUPERVISORCLUSTER \\
          --insecure-skip-tls-verify \\
          -u administrator@vsphere.local"

sleep 3
execCmd "kubectl config use-context $GUEST_CLUSTER"
execCmd "kubectl get ns"
execCmd "kubectl get nodes -o wide"

prtHead "Verify the new Workload cluster ($GUEST_CLUSTER) in vSphere ($TDH_TKGMC_VSPHERE_SERVER)"
prtText " - inspect 'Hosts and Clusters'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Cleanup and delete Kubernetes Cluster"
if [ "$NATIVE" == "0" ]; then
  echo "       To delete the cluster perform the following commands"
  echo "       => ../../tools/${TDH_TOOLS}.sh"
  echo "          tdh-tools:/$ kubectl config use-context $TDH_TKGMC_SUPERVISORCLUSTER"
  echo "          tdh-tools:/$ kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"
  echo "          tdh-tools:/$ exit"
else
  echo "       To delete the cluster perform the following commands  "
  echo "       => kubectl config use-context $TDH_TKGMC_SUPERVISORCLUSTER"
  echo "       => kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"
fi

prtText ""

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
