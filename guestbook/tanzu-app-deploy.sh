#!/bin/bash
# ============================================================================================
# File: ........: tanzu-app-deploy.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Upload files to the tanzu-demo-hub S3 Bucket (works only for Sacha Dubois)
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

APPNAME=guestbook
NAMESPACE=$APPNAME
BLOCKCHAIN_HOME=/tmp/$APPNAME

if [ -d $BLOCKCHAIN_HOME ]; then 
  echo "ERROR: $BLOCKCHAIN_HOME directory already exist, run tanzu-app-delete.sh fitst"; exit 1
fi

if [ -f $HOME/.tanzu-demo-hub.cfg ]; then 
  . $HOME/.tanzu-demo-hub.cfg
else
  echo "ERROR: $HOME/.tanzu-demo-hub.cfg not found"; exit 1
fi

git -C /tmp clone https://github.com/pivotal-sadubois/$APPNAME.git

# --- CREATE DEVELOPER NAMESPACE ---
cd $HOME/tanzu-demo-hub/scripts && ./tap-create-developer-namespace.sh $NAMESPACE 

# --- SETUP POSGRESS DB ---
kubectl delete secret regsecret -n $NAMESPACE > /dev/null 2>&1
kubectl create secret --namespace=$NAMESPACE docker-registry regsecret \
   --docker-server=https://registry.tanzu.vmware.com \
   --docker-username=$TDH_REGISTRY_VMWARE_USER \
   --docker-password=$TDH_REGISTRY_VMWARE_PASS

cd /tmp/$APPNAME/user-profile-database
kubectl -n $APPNAME create -f postgres-service-binding.yaml 2> /dev/null
kubectl -n $APPNAME create -f postgres-class.yaml 2> /dev/null
kubectl -n $APPNAME create -f postgres.yaml 

sleep 30

kubectl -n $APPNAME get all


exit

cd $BLOCKCHAIN_HOME && tanzu apps workload apply \
  --file config/workload-postgres.yaml \
  --namespace $NAMESPACE \
  --local-path . \
  --yes \
  --tail
