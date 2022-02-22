#!/bin/bash
# ============================================================================================
# File: ........: deploy-workload-cluster.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Workload Cluster on vSphere
# ============================================================================================

export TDH_DEMO_DIR="tkg-vsphere-service"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tkg-vsphere-service"
export GUEST_CLUSTER=tkg-cluster-1

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

[ -f $TDHHOME/functions ] &&  . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

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

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
runTDHtoolsDemos wcp

# --- SET CONTEXT ---
#cmdLoop kubectl config use-context $TDH_CONTEXT

if [ "$VSPHERE_TKGS_VCENTER_SERVER" == "" -o "$VSPHERE_TKGS_VCENTER_ADMIN" == "" -o "$VSPHERE_TKGS_VCENTER_PASSWORD" == "" ]; then 
  echo "ERROR: Please provide vSphere Cluster credentionals in $HOME/.tanzu-demo-hub.cfg : "
  echo "         export VSPHERE_TKGS_VCENTER_SERVER=wcp.haas-XYZ.pez.vmware.com"
  echo "         export VSPHERE_TKGS_VCENTER_ADMIN=administrator@vsphere.local"
  echo "         export VSPHERE_TKGS_VCENTER_PASSWORD=<password>"
  echo "         export VSPHERE_TKGS_SUPERVISOR_CLUSTER=wcp.haas-490.pez.vmware.com"
  exit 1
fi

# --- VERIFY SUPERVISOR CLUSTER LOGIN --- 
export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_TKGS_VCENTER_PASSWORD
kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER -u $VSPHERE_TKGS_VCENTER_ADMIN > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: can not login to vSphere Supervisor Cluster: $VSPHERE_TKGS_VCENTER_SERVER"
fi

# --- SET ENVIRONMENT ---
[ "$VSPHERE_NAMESPACE" == "" ] && export VSPHERE_NAMESPACE=tanzu-demo-hub

# --- CLEANUP ---
cmdLoop kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER > /dev/null 2>&1
cmdLoop kubectl get tanzukubernetescluster -n $VSPHERE_NAMESPACE -o json > /tmp/output.json 
nam=$(jq -r --arg key "$GUEST_CLUSTER" '.items[] | select(.metadata.name == $key).metadata.name' /tmp/output.json)
if [ "$nam" == "$GUEST_CLUSTER" ]; then 
  echo " INFO: Deleting leftover TKG Cluster ($GUEST_CLUSTER) from previous demo. This"
  echo "       may take a couple of minues."
  echo ""
  cmdLoop kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER --wait=true > /dev/null 2>&1
fi

prtHead "Login to the vSphere Envifonment on (http://$VSPHERE_TKGS_VCENTER_SERVER / $VSPHERE_TKGS_VCENTER_ADMIN)" 
prtText " - inspect 'Hosts and Clusters'"
prtText " - inspect 'Workload Management'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Create a new vSphere Namespace '$VSPHERE_NAMESPACE'"
prtText " - Menu -> 'Workload Management' => New Namespace"
prtText "      - Name: $VSPHERE_NAMESPACE => Create"
prtText " - Namespace -> '$VSPHERE_NAMESPACE' -> Summary"
#prtText "      - Storage -> Add Storage -> pacific.gold-storage-policy"
prtText "      - Storage -> Add Storage -> tanzu"
prtText "      - Permissions"
prtText "      - Capacity and Usage"
prtText "      - VM Servic -> Add VM Class"
prtText "           best-effort-medium, guaranteed-medium"
prtText ""
prtText "press 'return' to continue"; read x


prtHead "Login to the vSphere Supervisor Cluster ($VSPHERE_TKGS_SUPERVISOR_CLUSTER) and set Environment and Context"
execCmd "kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER -u $VSPHERE_TKGS_VCENTER_ADMIN"
#execCmd "kubectl config get-contexts"
#execCmd "kubectl config get-clusters"
execCmd "kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER"

prtHead "Create a Kubernetes Cluster Config ($GUEST_CLUSTER)"
execCmd "kubectl get tanzukubernetesreleases"
execCat "files/tkg-cluster-1.yaml"
execCmd "kubectl apply -f files/tkg-cluster-1.yaml --wait=true"

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
          --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER \\
          --insecure-skip-tls-verify \\
          -u administrator@vsphere.local"

sleep 3
execCmd "kubectl config use-context $GUEST_CLUSTER"
execCmd "kubectl get ns"
execCmd "kubectl get nodes -o wide"

prtHead "Verify the new Workload cluster ($GUEST_CLUSTER) in vSphere ($VSPHERE_TKGS_VCENTER_SERVER)"
prtText " - inspect 'Hosts and Clusters'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Cleanup and delete Kubernetes Cluster"
if [ "$NATIVE" == "0" ]; then
  echo "       To delete the cluster perform the following commands"
  echo "       => ../../tools/${TDH_TOOLS}.sh"
  echo "          tdh-tools:/$ kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER"
  echo "          tdh-tools:/$ kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"
  echo "          tdh-tools:/$ exit"
else
  echo "       To delete the cluster perform the following commands  "
  echo "       => kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER"
  echo "       => kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"
fi

prtText ""

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
