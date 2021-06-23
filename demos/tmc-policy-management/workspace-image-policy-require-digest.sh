#!/bin/bash
# ============================================================================================
# File: ........: demo-privileged-access.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

export NAMESPACE="image-policy-digest-demo"
export NAMESPACE_TEST="demo-apps-test"
export NAMESPACE_PROD="demo-apps-prod"
export WORKSPACE_TEST="tdh-ws-test"
export WORKSPACE_PROD="tdh-ws-prod"

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

if [ -f $HOME/.tanzu-demo-hub.cfg ]; then 
  . $HOME/.tanzu-demo-hub.cfg
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                        _____ __  __  ____   ____       _ _                           '
echo '                       |_   _|  \/  |/ ___| |  _ \ ___ | (_) ___ _   _                '
echo '                         | | | |\/| | |     | |_) / _ \| | |/ __| | | |               '
echo '                         | | | |  | | |___  |  __/ (_) | | | (__| |_| |               '
echo '                         |_| |_|  |_|\____| |_|   \___/|_|_|\___|\__, |               '
echo '                                                                 |___/                '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                      TMC Image Registry Policies - require-digest                    '
echo '                               by Sacha Dubois, VMware Inc                            '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_LB_CONTOUR)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
DOMAIN=${TDH_LB_CONTOUR}.${TDH_ENVNAME}.${TDH_DOMAIN}

if [ ! -x "/usr/local/bin/docker" ]; then 
  echo "ERROR: Docker binaries are not installed"
  echo "       => brew install docker"
  exit 1
fi

# --- HARBOR CONFIG ---
TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
if [ "$TDH_HARBOR_REGISTRY_ENABLED" != "true" ]; then 
  echo "ERROR: The Harbor registry is required to run this demo"
  exit
else
  docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: failed to login to registry"
    echo "       => docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
    exit
  fi
fi

if [ "$TDH_MANAGED_BY_TMC" == "true" ]; then 
  tmcCheckLogin

  TDH_CLUSTER_NAME=$(getConfigMap tanzu-demo-hub TDH_CLUSTER_NAME)
  TDH_MANAGEMENT_CLUSTER=$(getConfigMap tanzu-demo-hub TDH_MANAGEMENT_CLUSTER)
  TDH_PROVISONER_NAME=$(getConfigMap tanzu-demo-hub TDH_PROVISONER_NAME)
  TDH_MISSION_CONTROL_ACCOUNT_NAME=$(getConfigMap tanzu-demo-hub TDH_MISSION_CONTROL_ACCOUNT_NAME)

  tdh_verifyTKGcluster
else
  echo "ERROR: This demo requires to have the cluster managed by Tanzu Mission Control (TMC)"
  exit
fi

# --- CLEANUP TMC RESSOURCES ---
for n in $(tmc workspace image-policy list --workspace-name $WORKSPACE_PROD | egrep " tdh-" | awk '{ print $1 }'); do
  tmc workspace image-policy delete --workspace-name $WORKSPACE_PROD $n > /dev/null 2>&1
done

for n in $(tmc workspace image-policy list --workspace-name $WORKSPACE_TEST | egrep " tdh-" | awk '{ print $1 }'); do
  tmc workspace image-policy delete --workspace-name $WORKSPACE_TEST $n > /dev/null 2>&1
done

tmc cluster namespace delete --cluster-name $TDH_CLUSTER_NAME -p $TDH_PROVISONER_NAME -m $TDH_MANAGEMENT_CLUSTER $NAMESPACE_TEST > /dev/null 2>&1
tmc cluster namespace delete --cluster-name $TDH_CLUSTER_NAME -p $TDH_PROVISONER_NAME -m $TDH_MANAGEMENT_CLUSTER $NAMESPACE_PROD > /dev/null 2>&1
tmc cluster namespace delete --cluster-name $TDH_CLUSTER_NAME \
   -p $TDH_PROVISONER_NAME -m $TDH_MANAGEMENT_CLUSTER demo-apps-test > /dev/null 2>&1
tmc cluster namespace delete --cluster-name $TDH_CLUSTER_NAME \
   -p $TDH_PROVISONER_NAME -m $TDH_MANAGEMENT_CLUSTER demo-apps-prod > /dev/null 2>&1
tmc workspace delete "tdh-ws-prod" > /dev/null 2>&1
tmc workspace delete "tdh-ws-test" > /dev/null 2>&1

prtHead "Create TMC Workspace for Production and Testing ressources"
execCmd "tmc workspace create -n \"tdh-ws-prod\""
execCmd "tmc workspace create -n \"tdh-ws-test\""

prtHead "Create TMC Managed Namespace ($NAMESPACE_TEST) within the $TDH_CLUSTER_NAME cluster"
echo "     -----------------------------------------------------------------------------------------------------------"
echo "     tmc cluster namespace create"
echo "       -c $(alignStr $TDH_CLUSTER_NAME) # TKG Cluster Name"
echo "       -p $(alignStr $TDH_PROVISONER_NAME) # TMC Provisioner Name"
echo "       -m $(alignStr $TDH_MANAGEMENT_CLUSTER) # TKG Management Cluster"
echo "       -k $(alignStr $WORKSPACE_PROD) # TMC Workspace Name"
echo "       -n $(alignStr $NAMESPACE_TEST) # Kubernetes Cluster Namespace"
echo "     -----------------------------------------------------------------------------------------------------------"

execCmd "tmc cluster namespace create -c $TDH_CLUSTER_NAME -m $TDH_MANAGEMENT_CLUSTER -p $TDH_PROVISONER_NAME -n $NAMESPACE_TEST -k $WORKSPACE_TEST"
execCmd "tmc cluster namespace --cluster-name $TDH_CLUSTER_NAME -m $TDH_MANAGEMENT_CLUSTER -p $TDH_PROVISONER_NAME --workspace-name $WORKSPACE_TEST list"

prtHead "Create TMC Managed Namespace ($NAMESPACE_PROD) within the $TDH_CLUSTER_NAME cluster"
echo "     -----------------------------------------------------------------------------------------------------------"
echo "     tmc cluster namespace create"
echo "       -c $(alignStr $TDH_CLUSTER_NAME) # TKG Cluster Name"
echo "       -p $(alignStr $TDH_PROVISONER_NAME) # TMC Provisioner Name"
echo "       -m $(alignStr $TDH_MANAGEMENT_CLUSTER) # TKG Management Cluster"
echo "       -k $(alignStr $WORKSPACE_PROD) # TMC Workspace Name"
echo "       -n $(alignStr $NAMESPACE_PROD) # Kubernetes Cluster Namespace"
echo "     -----------------------------------------------------------------------------------------------------------"

execCmd "tmc cluster namespace create -c $TDH_CLUSTER_NAME -m $TDH_MANAGEMENT_CLUSTER -p $TDH_PROVISONER_NAME -n $NAMESPACE_PROD -k $WORKSPACE_PROD"
execCmd "tmc cluster namespace --cluster-name $TDH_CLUSTER_NAME -m $TDH_MANAGEMENT_CLUSTER -p $TDH_PROVISONER_NAME --workspace-name $WORKSPACE_PROD list"
execCmd "kubectl get ns"

prtHead "Show available Image-Policy templates"
execCmd "tmc organization image-policy template list"

prtHead "Create Image Policy - Require Digest for Workspace ($WORKSPACE_PROD)"
execCmd "tmc workspace image-policy create -r require-digest --workspace-name $WORKSPACE_PROD -n tdh-require-digest"
sleep 20
execCmd "kubectl get vmware-system-tmc-allowed-images-v1.constraints.gatekeeper.sh"
execCmd "kubectl describe vmware-system-tmc-allowed-images-v1.constraints.gatekeeper.sh"

# --- ENVIRONMENT VARIABLES ---
DOCKER_BUILD_DIR=/tmp/docker_build
rm -rf $DOCKER_BUILD_DIR

echo "     Create and deploy a docker container without a digests and try to deploy it into the"
echo "     $NAMESPACE_TEST and $NAMESPACE_PROD namespace"
echo "     -----------------------------------------------------------------------------------------------------------"

prtHead "Create temporary Docker Build directory ($DOCKER_BUILD_DIR)"
slntCmd "mkdir -p $DOCKER_BUILD_DIR"
lineFed

prtHead "Create README"
slntCmd "echo \"# Busybox Docker container without digest for\"       >  $DOCKER_BUILD_DIR/README"
slntCmd "echo \"# for TMC security Policies testing\"                 >> $DOCKER_BUILD_DIR/README"
lineFed

prtHead "Create Dockerfile for 'bad' Container"
slntCmd "echo \"# BUILD A 'BAD' DOCKER CONTAINER WITHOUT DIGEST\"     >  $DOCKER_BUILD_DIR/Dockerfile"
slntCmd "echo \"FROM busybox\"                                        >> $DOCKER_BUILD_DIR/Dockerfile"
slntCmd "echo \"CMD echo Hello world\"                                >> $DOCKER_BUILD_DIR/Dockerfile"
slntCmd "echo \"COPY ./README /README\"                               >> $DOCKER_BUILD_DIR/Dockerfile"
execCmd "cat $DOCKER_BUILD_DIR/Dockerfile"

prtHead "Build the Docker Container"
execCmd "cd $DOCKER_BUILD_DIR && docker build -t busybox-no-digest ."
execCmd "docker images busybox-no-digest"

prtHead "Push Docker container (busybox-no-digest:latest) to the Harbor Registry"
slntCmd "docker tag busybox-no-digest:latest $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/busybox-no-digest:latest"
execCmd "docker push $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/busybox-no-digest:latest"

prtHead "Deploy Docker container (busybox-no-digest:latest) to kubernetes namespace: $NAMESPACE_TEST"
execCmd "kubectl -n $NAMESPACE_TEST run busybox --image=$TDH_HARBOR_REGISTRY_DNS_HARBOR/library/busybox-no-digest:latest --restart=Never -- sh"

prtHead "Deploy Docker container (busybox-no-digest:latest) to kubernetes namespace: $NAMESPACE_PROD"
execCmd "kubectl -n $NAMESPACE_PROD run busybox --image=$TDH_HARBOR_REGISTRY_DNS_HARBOR/library/busybox-no-digest:latest --restart=Never -- sh"

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"


exit
#tmc policy templates list
#tmc organization image-policy create
#tmc organization image-policy template list
#tmc workspace image-policy create [
#tmc workspace image-policy create -r require-digest --workspace-name tdh-ws-prod
#tmc cluster namespace-quota-policy
exit

prtHead "Create namespace $NAMESPACE_TEST and $NAMESPACE_PROD to host the Demo"
execCmd "kubectl create namespace $NAMESPACE_TEST"
execCmd "kubectl create namespace $NAMESPACE_PROD"

exit

