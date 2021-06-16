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
export MGMT_CLUSTER=$1
export GUEST_CLUSTER=capi-cluster-01

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '               _____ _  ______    ____ _           _             _          _         '
echo '              |_   _| |/ / ___|  / ___| |_   _ ___| |_ ___ _ __ / \   _ __ (_)        '
echo '                | | |   / |  _  | |   | | | | / __| __/ _ \  __/ _ \ |  _ \| |        '
echo '                | | | . \ |_| | | |___| | |_| \__ \ ||  __/ | / ___ \| |_) | |        '
echo '                |_| |_|\_\____|  \____|_|\__,_|___/\__\___|_|/_/   \_\ .__/|_|        '
echo '                                                                     |_|              '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '               VMware Tanzu Kubernetes Grid (TKG) - Kubernetes Cluster API Demo'
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

if [ ! -f /usr/local/bin/clusterctl ]; then
  echo "ERROR: ClusterAPI utility (/usr/local/bin/clusterctl) is not installed, please download it from here:"
  echo "       => https://cluster-api.sigs.k8s.io/user/quick-start.html"
  exit
fi

# --- VERIFY THE MANAGEMENT CLUSTER ---
if [ "$MGMT_CLUSTER" == "" ]; then
  echo "TKG Management Clusters:"
  messageLine
  tanzu config server list
  messageLine

  echo ""
  echo "USAGE: $0 <management-cluster>"
  exit
else
  tanzu login --server $MGMT_CLUSTER > /dev/null
  MGMT_CLUSTER=$(kubectl config get-clusters | grep $MGMT_CLUSTER | head -1)
  if [ "${MGMT_CLUSTER}" == "" ]; then
    echo "ERROR: No Management cluster configured, Please provision one with the 'deployTKGmc' utility"
    exit
  else
    MGMT_CONTEXT=$(kubectl config view -o json | jq -r --arg key $MGMT_CLUSTER '.contexts[] | select(.context.cluster == $key).name')

    kubectl config set-cluster $MGMT_CLUSTER > /dev/null 2>&1
    kubectl config use-context $MGMT_CONTEXT > /dev/null 2>&1
  fi
fi

ctx=$(kubectl config view -o json | jq -r --arg key $MGMT_CLUSTER '.contexts[] | select(.context.cluster == $key).name')
usr=$(kubectl config view -o json | jq -r --arg key $MGMT_CLUSTER '.contexts[] | select(.context.cluster == $key).context.user')

if [ 1 -eq 1 ]; then
prtHead "Show deployed TKG Management Clusters"
execCmd "tanzu config server list"
execCmd "tanzu cluster list --include-management-cluster $MGMT_CLUSTER"
execCmd "kubectl get clusters --all-namespaces"

prtHead "Show Microsoft Azure Resources of the Management Cluster"
execCmd "az group list -o table"
execCmd "az vm list -g $MGMT_CLUSTER -o table"
execCmd "az resource list -g tkgmc-azure-sadubois -o table"

prtHead "Login to the TKG Management Cluster ($MGMT_CLUSTER) and set Environment and Context"
execCmd "tanzu login --server $MGMT_CLUSTER"
execCmd "kubectl config set-cluster $MGMT_CLUSTER"
execCmd "kubectl config use-context $ctx"
execCmd "tanzu management-cluster get"

AZURE_CONTROL_PLANE_MACHINE_TYPE=$(grep "AZURE_CONTROL_PLANE_MACHINE_TYPE" ~/.tanzu-demo-hub/config/${MGMT_CLUSTER}.yaml | sed 's/^.*: //g')
AZURE_LOCATION=$(grep "AZURE_LOCATION" ~/.tanzu-demo-hub/config/${MGMT_CLUSTER}.yaml | sed 's/^.*: //g')
AZURE_NODE_MACHINE_TYPE=$(grep "AZURE_NODE_MACHINE_TYPE" ~/.tanzu-demo-hub/config/${MGMT_CLUSTER}.yaml | sed 's/^.*: //g')
AZURE_SUBSCRIPTION_ID=$(grep "AZURE_SUBSCRIPTION_ID" ~/.tanzu-demo-hub/config/${MGMT_CLUSTER}.yaml | sed 's/^.*: //g')

export AZURE_CONTROL_PLANE_MACHINE_TYPE=$AZURE_CONTROL_PLANE_MACHINE_TYPE
export AZURE_LOCATION=$AZURE_LOCATION
export AZURE_NODE_MACHINE_TYPE=$AZURE_NODE_MACHINE_TYPE
export AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID

prtHead "Create a Kubernetes Cluster Config"
execCmd "kubectl get tanzukubernetesreleases"

slntCmd "export AZURE_CONTROL_PLANE_MACHINE_TYPE=$AZURE_CONTROL_PLANE_MACHINE_TYPE"
slntCmd "export AZURE_LOCATION=$AZURE_LOCATION"
slntCmd "export AZURE_NODE_MACHINE_TYPE=$AZURE_NODE_MACHINE_TYPE"
slntCmd "export AZURE_SUBSCRIPTION_ID=$(maskPassword \"$AZURE_SUBSCRIPTION_ID\")"
#slntCmd "clusterctl config cluster $GUEST_CLUSTER --kubernetes-version v1.16.3 --control-plane-machine-count=3 --worker-machine-count=3 > /tmp/$GUEST_CLUSTER.yaml"
slntCmd "clusterctl config cluster $GUEST_CLUSTER --kubernetes-version v1.16.3 --control-plane-machine-count=3 --worker-machine-count=1 > /tmp/$GUEST_CLUSTER.yaml"
execCat "/tmp/$GUEST_CLUSTER.yaml"
execCmd "kubectl apply -f /tmp/$GUEST_CLUSTER.yaml --wait=true"

execCmd "kubectl get clusters --all-namespaces"

stt=""
while [ "$stt" != "True" ]; do
  stt=$(kubectl get clusters -n default -o json 2>/dev/null | \
   jq -r --arg key "$GUEST_CLUSTER" '.items[] | select(.metadata.name == $key).status.conditions[] | select(.type == "Ready").status' 2>/dev/null)
  sleep 10
done

prtHead "Show cluster creation progress"
execCmd "kubectl get clusters --all-namespaces"

prtHead "Describe cluster details"
execCmd "kubectl get kubeadmcontrolplane --all-namespaces"
execCmd "clusterctl describe cluster $GUEST_CLUSTER"

kubectl config use-context $ctx >/dev/null 2>&1
prtHead "Get Cluster Permissions and set context to the $GUEST_CLUSTER cluster"
slntCmd "clusterctl get kubeconfig $GUEST_CLUSTER > /tmp/$GUEST_CLUSTER.kubeconfig"
export KUBECONFIG=/tmp/capi-cluster-01.kubeconfig:~/.kube/config
slntCmd "export KUBECONFIG=/tmp/$GUEST_CLUSTER.kubeconfig:~/.kube/config"
execCmd "kubectl config use-context $GUEST_CLUSTER-admin@$GUEST_CLUSTER"
execCmd "kubectl get nodes -o wide"

prtHead "Show Microsoft Azure Resources of the Management Cluster"
execCmd "az group list -o table"
execCmd "az vm list -g $GUEST_CLUSTER -o table"
execCmd "az resource list -g $GUEST_CLUSTER -o table"

#https://cluster-api.sigs.k8s.io/user/quick-start.html
prtHead "Install the CNI"
prtText " - The control planes won’t be Ready until we install a CNI"

kubectl config use-context $GUEST_CLUSTER-admin@$GUEST_CLUSTER > /dev/null 2>&1
execCmd "kubectl config use-context $GUEST_CLUSTER-admin@$GUEST_CLUSTER"
execCmd "kubectl apply -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml"

cnt=1
while [ $cnt -ne 0 ]; do
  cnt=$(tanzu cluster list | grep -c creating) 
  sleep 10
done

execCmd "tanzu cluster list"

kubectl config use-context $ctx >/dev/null 2>&1

prtHead "Scale worker nodes by editing the CluserAPI configuration"
kubectl config use-context $ctx >/dev/null 2>&1
execCmd "kubectl config use-context $ctx"
slntCmd "cat /tmp/$GUEST_CLUSTER.yaml | sed 's/replicas: 1/replicas: 3 ## Scaled by Sacha Dubois/g' > /tmp/${GUEST_CLUSTER}_new.yaml"
execCat "/tmp/${GUEST_CLUSTER}_new.yaml"
execCmd "kubectl apply -f /tmp/$GUEST_CLUSTER.yaml --wait=true"
fi

prtText ""

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit

sdubois-a02:tkg-cluster-api sdu$ ./cluster-api.sh tkgmc-azure-sadubois
sdubois-a02:tkg-cluster-api sdu$ rm -f asciinema/demo.cast; asciinema rec -i 2.5 asciinema/demo.cast
