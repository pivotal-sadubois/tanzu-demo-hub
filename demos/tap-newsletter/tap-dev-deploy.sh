#!/bin/bash
# ############################################################################################
# File: ........: tap-dev-deploy.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Workload Cluster
# ############################################################################################

export TDHHOME=$(cd "$(pwd)/$(dirname $0)"; cd ../..; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)"; pwd)
export DEBUG=0
export NATIVE=0
export DEPLOY_TKG_CLEAN=0
export TDHV2_MANAGEMENT_CLUSTER
export TDHV2_WORKLOAD_CLUSTER
export TDHV2_DEPLOYMENT
export TDHV2_DNS_SUBDOMAIN
export TDH_USER=$USER

echo gaga
echo "TANZU_DEMO_HUB:$TANZU_DEMO_HUB"
echo "TDHHOME:$TDHHOME"
echo "TDHPATH:$TDHPATH"

exit

# --- SETTING FOR TDH-TOOLS ---
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# --- CHECK FOR BASIC COMANDS ---
checkCLIcommands        BASIC

usage() {
  echo ""
  echo "USAGE: $0 [options] -m <management-cluster> -c <tdh-deployment> --subdomain <subdomain> [--debug]"
  echo "            Options:  --delete                  # Delete Workload Cluster"
  echo "                      --native                  # Use 'native' installed tools instead of the tdh-tools container"
  echo "                      --subdomain <domain>      # DNS Subdomain <subdomain>.<yourdomain>.com"

  echo ""
}

while [ "$1" != "" ]; do
  case $1 in
    -m)            TDHV2_MANAGEMENT_CLUSTER=$2;;
    -c)            TDHV2_DEPLOYMENT=$2;;
    --subdomain)   TDHV2_DNS_SUBDOMAIN=$2;;
    --debug)       DEBUG=1;;
    --delete)      DEPLOY_TKG_CLEAN=1;;
    --native)      NATIVE=1;;
  esac
  shift
done

if [ "${TDHV2_MANAGEMENT_CLUSTER}" == "" -o "${TDHV2_DEPLOYMENT}" == "" -o "${TDHV2_DNS_SUBDOMAIN}" == "" ]; then
  [ "${TDHV2_MANAGEMENT_CLUSTER}" == "" ] && listTKGmcV2
  [ "${TDHV2_DEPLOYMENT}" == "" ] && listClusterConfigV2

  usage; exit 0
fi

[ -f $HOME/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}.cfg ] && TDHV2_MANAGEMENT_CLUSTER=${TDHV2_MANAGEMENT_CLUSTER}

# --- VERIFY DEPLOYMENT ---
if [ -f $HOME/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}.cfg ]; then
  TMC_DEPLOYMENT_CONFIG=${HOME}/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}.cfg
  TDH_TKGMC_NAME=$(egrep "^TDH_TKGMC_NAME=" $TMC_DEPLOYMENT_CONFIG | awk -F'=' '{ print $2 }' | sed 's/"//g')
  TDH_TKGMC_TOOLS_CONTAINER=$(egrep "^TDH_TKGMC_TOOLS_CONTAINER=" $TMC_DEPLOYMENT_CONFIG | awk -F'=' '{ print $2 }' | sed 's/"//g' | awk -F'-' '{ print $NF }')
  K8S_TKGMC=$(echo $TDH_TKGMC_TOOLS_CONTAINER | awk -F'.' '{ printf("%s.%s\n",$1,$2) }')

  . $HOME/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}.cfg
else
  echo "ERROR: Deployment file $TDHV2_MANAGEMENT_CLUSTER can not be found in the directory:"
  echo "       $HOME/.tanzu-demo-hub/config"
  exit 1
fi

if [ -f $TDHPATH/deployments/${TDHV2_DEPLOYMENT}.j2 ]; then
 tdh_tools=$(head -10 $TDHPATH/deployments/${TDHV2_DEPLOYMENT}.j2 | yq -o json | jq -r '.tdh_deployment.tdh_tools')
else
  echo "ERROR: Configuration file $TDHV2_MANAGEMENT_CLUSTER can not be found in the directory:"
  echo "       $TDHPATH/deployments or $HOME/.tanzu-demo-hub/config"
  exit 1
fi

export TDHV2_MC_CONFIG=$HOME/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}
export TDHV2_WC_CONFIG=$HOME/.tanzu-demo-hub/config/${TDHV2_MANAGEMENT_CLUSTER}
export TDHV2_SECRETS=$HOME/.tanzu-demo-hub
export AWS_HOSTED_DNS_DOMAIN=$AWS_ROUTE53_DNS_DOMAIN
export TDH_REGISTRY_VMWARE_NAME='registry.pivotal.io'
export TDH_REGISTRY_DOCKER_NAME='docker.io'

#############################################################################################################################
################################### EXECUTING CODE WITHIN  TDH-TOOLS DOCKER CONTAINER  ######################################
#############################################################################################################################
runTDHtools "tkg" "$tdh_tools" "Deploy TKG Workload Cluster" "/home/tanzu/tanzu-demo-hub/$CMD_EXEC" "$CMD_ARGS"

echo gaga
echo "TANZU_DEMO_HUB:$TANZU_DEMO_HUB"
echo "TDHPATH:$TDHPATH"
exit

checkCLIcommands BASIC
checkCLIcommands TOOLS

exit

# --- CONVERT TDH CONFIG VARIABLES TO YAML ---
convertTDHconfig
convertTDHsecrets
createTDHdeployment

#############################################################################################################################
######################### CREATE TKG CLUSTER AND ATTACH TO TMC AND INSTALL TMC INTEGRATION ##################################
#############################################################################################################################
for clu in $(getYAML WC_CLUSTER_LIST); do
  TDHV2_WORKLOAD_CLUSTER=$clu

  vsphereSupervisorClusterLoginV2    $(getYAML MC_NAME)
  setKubernetesContextV2             $(getYAML MC_KUBECONFIG)
  tanzuConfigServerV2                $(getYAML MC_NAME)

  setKubernetesContextV2             $(getYAML MC_KUBECONFIG)
  tkgCreateClusterV2
  tmcAttachClusterV2 
  createTLSCertificateV2 $clu

  messageTitle "Tanzu Package Management"
  installPackageRepositories
  installTanzuPackageCertManager
  installTanzuPackageContour
  installTanzuPackageHarbor

  #installBuildService               ## Tanzu Build Service (TBS)
  #installTanzuDataPostgres          ## Tanzu Data SQL
  #installSpringCloudGateway
  #installMinio
  #installKubeapps
  #installGitea
  #installJenkins
  #installArgoCD
  #installGitLab
  #installKubeernetesDashboard       ## Kubernetes Dashboard
  installTAPV2                       ## Tanzu Application Platform (TAP)
done

mergeKubeconfigFiles
configureAppLiveView
configureSupplyChainBasic

exit
