#!/bin/bash
# ============================================================================================
# File: ........: tbs-petclinic-cleanup.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Tanzu Build Service (TBS) Demo with the Spring Petclinic Application
# ============================================================================================

export TDH_DEMO_DIR="tbs-spring-petclinic"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tbs-spring-petclinic"

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
runTDHtoolsDemos

TDH_SERVICE_REGISTRY_DOCKER=$(getConfigMap tanzu-demo-hub TDH_SERVICE_REGISTRY_DOCKER)
TDH_SERVICE_REGISTRY_HARBOR=$(getConfigMap tanzu-demo-hub TDH_SERVICE_REGISTRY_HARBOR)
TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_LB_CONTOUR)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

TBS_SOURCE_APP=spring-petclinic
TBS_SOURCE_DIR=/tmp/$TBS_SOURCE_APP

# --- CLEANUP ---
kp secret delete secret-registry-vmware > /dev/null 2>&1
kp secret delete secret-registry-harbor > /dev/null 2>&1
kp secret delete secret-repo-git > /dev/null 2>&1
kp image delete spring-petclinic > /dev/null 2>&1
rm -rf /tmp/spring-petclinic  ## REMOVE GIT REPOSITORY (PET-CLINIC)
pkill com.docker.cli
kubectl delete namespace $NAMESPACE > /dev/null 2>&1
