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
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$NAMESPACE

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
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
echo '              TMC Image Registry Policies - Block Images with no Digests              '
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

if [ "$TDH_MANAGED_BY_TMC" != "true" ]; then 
  echo "ERROR: This demo requires to have the cluster managed by Tanzu Mission Control (TMC)"
  exit
fi

# --- CLEANUP TMC RESSOURCES ---
tmc workspace delete "tdh-ws-prod" > /dev/null 2>&1
tmc workspace delete "tdh-ws-test" > /dev/null 2>&1

# --- ENVIRONMENT VARIABLES ---
DOCKER_BUILD_DIR=/tmp/docker_build

if [ 1 -eq 0 ]; then
# --- CLEANUP DEPLOYMENT ---
kubectl delete namespace $NAMESPACE_TEST > /dev/null 2>&1
kubectl delete namespace $NAMESPACE_PROD > /dev/null 2>&1
rm -rf $DOCKER_BUILD_DIR
echo "DOCKER_BUILD_DIR:$DOCKER_BUILD_DIR"

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
fi

prtHead "Create TMC Workspace for Production and Testing ressources"
execCmd "tmc workspace create -n \"tdh-ws-prod\""
execCmd "tmc workspace create -n \"tdh-ws-test\""

#tmc policy templates list
#tmc organization image-policy create
#tmc organization image-policy template list
#tmc workspace image-policy create [
exit

prtHead "Create namespace $NAMESPACE_TEST and $NAMESPACE_PROD to host the Demo"
execCmd "kubectl create namespace $NAMESPACE_TEST"
execCmd "kubectl create namespace $NAMESPACE_PROD"

exit

prtHead "Create deployment for the ingress tesing app"
execCmd "kubectl create deployment echoserver --image=datamanos/echoserver --port=8080 -n $NAMESPACE"
sleep 3
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Investigate the failed pod"
podname=$(kubectl get pods -n role-binding-demo | grep "CreateContainerConfigError" | awk '{ print $1 }')
execCmd "kubectl describe pod $podname -n $NAMESPACE"
read x

prtHead "Create Policy to Allow Privileged Containers"
execCmd "kubectl create rolebinding tanzu-demo-hub-privileged-$NAMESPACE-role-binding \\
          --clusterrole=vmware-system-tmc-psp-privileged \\
          --group=system:authenticated \\
          -n $NAMESPACE"

prtHead "See all Role Bindings"
execCmd "kubectl -n $NAMESPACE get rolebinding"

prtHead "Restart Deployment"
execCmd "kubectl -n $NAMESPACE rollout restart deployment echoserver"
execCmd "kubectl -n $NAMESPACE get pods"

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment echoserver --type LoadBalancer --port=8080 -n $NAMESPACE"
sleep 3
execCmd "kubectl -n $NAMESPACE get svc,pods"

ipa=$(kubectl -n $NAMESPACE get service/echoserver -o json | jq -r '.status.loadBalancer.ingress[].hostname')
prtHead "Open WebBrowser and verify the deployment"
echo "     => curl http://${ipa}:8080"
echo ""

exit

