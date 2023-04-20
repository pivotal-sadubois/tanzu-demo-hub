#!/bin/bash
# ############################################################################################
# File: ........: tap-create-developer-namespace.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDHHOME=$HOME/tanzu-demo-hub
export NAMESPACE=$1

if  [ "$NAMESPACE" == "" ]; then 
  echo "Usage: $0 <namespace>"; exit 1
fi

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# --- VERIFY CLUSTER ACCESS ---
kubectl get ns > /tmp/error.log 2>&1; ret=$?
if [ $ret -ne 0 ]; then
  logMessages /tmp/error.log
  echo "ERROR: Kubernetes cluster not accessabel, please restart tdh-tools container to reinitiate cluster login"
  echo "       => tools/${TDH_TOOLS}.sh"
  exit
fi

REGISTRY_USERNAME="admin"
REGISTRY_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
REGISTRY_SERVER=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)

# --- CREATE NAMESPACE If IT DOES NOT EXIST ----
[ "$NAMESPACE" != "default" ] && kubectl create ns --dry-run=client -o yaml $NAMESPACE | kubectl apply -f -

tanzu secret registry add harbor-registry-credentials \
  --server $REGISTRY_SERVER \
  --username "$REGISTRY_USERNAME" \
  --password "$REGISTRY_PASSWORD" \
  --namespace "$NAMESPACE" \
  --verbose 0 >/dev/null 2>&1

kubectl -n $NAMESPACE create secret docker-registry vmware-registry-credentials \
          --docker-server=https://registry.tanzu.vmware.com/ \
          --docker-username=$TDH_REGISTRY_VMWARE_USER \
          --docker-password=$TDH_REGISTRY_VMWARE_PASS >/dev/null 2>&1

# --- CREATE TAP LABEL ---
kubectl label namespaces $NAMESPACE apps.tanzu.vmware.com/tap-ns=""

sleep 60

kubectl get secrets,serviceaccount,rolebinding,pods,workload,configmap -n $NAMESPACE 

exit

# not needed anymore because of tap namespace provisioner
cat <<EOF | kubectl -n "$NAMESPACE" apply -f - 2>/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: tap-registry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-deliverable
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deliverable
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-workload
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: workload
subjects:
  - kind: ServiceAccount
    name: default
EOF
