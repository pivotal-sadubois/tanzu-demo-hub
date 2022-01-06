#!/bin/bash
# ============================================================================================
# File: ........: tanzu-postgress-deploy-singleton.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================
# select * from pg_hba_file_rules;

export NAMESPACE="tanzu-data-postgres-demo"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE
export GUEST_CLUSTER=tkg-cluster-1

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '           _____ _  ______    __                     ____        _                    '
echo '          |_   _| |/ / ___|  / _| ___  _ __  __   __/ ___| _ __ | |__   ___ _ __ ___  '
echo '            | | |   / |  _  | |_ / _ \|  __| \ \ / /\___ \|  _ \|  _ \ / _ \  __/ _ \ '
echo '            | | | . \ |_| | |  _| (_) | |     \ V /  ___) | |_) | | | |  __/ | |  __/ '
echo '            |_| |_|\_\____| |_|  \___/|_|      \_/  |____/| .__/|_| |_|\___|_|  \___| '
echo '                                                             |_|                      ' 
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '               VMware Tanzu Kubernetes Grid (TKG) - Kubernetes Cluster API Demo'
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '



if [ "$VSPHERE_SERVER" == "" -o "$VSPHERE_USER" == "" -o "$VSPHERE_PASS" == "" ]; then 
  echo "ERROR: Please provide vSphere Cluster credentionals: "
  echo "         export VSPHERE_SERVER=wcp.haas-XYZ.pez.vmware.com"
  echo "         export VSPHERE_USER=administrator@vsphere.local"
  echo "         export VSPHERE_PASS=<password>"
  echo "         export SUPERVISOR_CLUSTER=wcp.haas-490.pez.vmware.com"
  exit 1
fi

nslookup $VSPHERE_SERVER > /dev/null 2>&1; ret=$?
if [ $? -ne 0 ]; then 
  echo "ERROR: can not resolv vSphere Supervisor Cluster: $VSPHERE_SERVER"
fi

# --- VERIFY SUPERVISOR CLUSTER LOGIN --- 
export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_PASS
kubectl vsphere login --insecure-skip-tls-verify --server $SUPERVISOR_CLUSTER -u $VSPHERE_USER > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: can not login to vSphere Supervisor Cluster: $VSPHERE_SERVER"
fi

[ "$VSPHERE_NAMESPACE" == "" ] && export VSPHERE_NAMESPACE=tanzu-demo

prtHead "Login to the vSphere Envifonment on (http://$VSPHERE_SERVER / $VSPHERE_USER)" 
prtText " - inspect 'Hosts and Clusters'"
prtText " - inspect 'Workload Management'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Create a new vSphere Namespace 'tanzu-demo'"
prtText " - Menu -> 'Workload Management' => New Namespace"
prtText "      - Name: tanzu-demo => Create"
prtText " - Namespace -> 'tanzu-demo' -> Summary"
#prtText "      - Storage -> Add Storage -> pacific.gold-storage-policy"
prtText "      - Storage -> Add Storage -> tanzu"
prtText "      - Permissions"
prtText "      - Capacity and Usage"
prtText "      - VM Servic -> Add VM Class"
prtText "           best-effort-small, guaranteed-small"
prtText ""
prtText "press 'return' to continue"; read x


prtHead "Login to the vSphere Supervisor Cluster ($SUPERVISOR_CLUSTER) and set Environment and Context"
execCmd "kubectl vsphere login --insecure-skip-tls-verify --server $SUPERVISOR_CLUSTER -u $VSPHERE_USER"
#execCmd "kubectl config get-contexts"
#execCmd "kubectl config get-clusters"
execCmd "kubectl config use-context $SUPERVISOR_CLUSTER"

prtHead "Create a Kubernetes Cluster Config ($GUEST_CLUSTER)"
execCmd "kubectl get tanzukubernetesreleases"
execCat "files/tkg-cluster-1.yaml"
execCmd "kubectl apply -f files/tkg-cluster-1.yaml --wait=true"

execCmd "kubectl get tanzukubernetescluster -n tanzu-demo"

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
          --server $SUPERVISOR_CLUSTER \\
          --insecure-skip-tls-verify \\
          -u administrator@vsphere.local"

execCmd "kubectl config use-context $GUEST_CLUSTER"
execCmd "kubectl get ns"
execCmd "kubectl get nodes -o wide"

prtHead "Verify the new Workload cluster ($GUEST_CLUSTER) in vSphere ($VSPHERE_SERVER)"
prtText " - inspect 'Hosts and Clusters'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Cleanup and delete Kubernetes Cluster"
execCmd "kubectl config use-context $SUPERVISOR_CLUSTER"
prtText "=> To delete the cluster"
#prtText "kubectl delete cluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"
prtText "kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER"

prtText ""

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit
