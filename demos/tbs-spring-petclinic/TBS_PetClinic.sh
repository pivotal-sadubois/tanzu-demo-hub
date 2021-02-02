#!/bin/bash
# ============================================================================================
# File: ........: TBS_PetClinic.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Demonstration for TBS spring-petclinic based on two different URL
# ============================================================================================

export DEMO_NAME=tbs-spring-petclinic
export DEMO_NAMESPACE=tbs-spring-petclinic
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/$DEMO_NAME

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '            ____             _               ____      _      ____ _ _       _        '
echo '           / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___| |_   / ___| (_)_ __ (_) ___   '
echo '           \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \ __| | |   | | |  _ \| |/ __|  '
echo '            ___) | |_) | |  | | | | | (_| | |  __/  __/ |_  | |___| | | | | | | (__   '
echo '           |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__|  \____|_|_|_| |_|_|\___|  '
echo '                 |_|                 |___/                                            '
echo '                                                                                      '
echo '                                   ____                                               '
echo '                                  |  _ \  ___ _ __ ___   ___                          '
echo '                                  | | | |/ _ \  _   _ \ / _ \                         '
echo '                                  | |_| |  __/ | | | | | (_) |                        '
echo '                                  |____/ \___|_| |_| |_|\___/                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                           Demonstration for Pivotal Build Service (PBS)              '
echo '                           by Sacha Dubois / Steve Schmidt, Pivotal Inc               '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

VerifyDemoEnvironment


exit

export TDH_TKGWC_NAME=tdh-1
export NAMESPACE="contour-ingress-demo"
export DOMAIN=${AWS_HOSTED_DNS_DOMAIN}

if [ "${TKG_CONFIG}" == "" ]; then
  echo "ERROR: environment variable TKG_CONFIG has not been set"; exit
fi

if [ "${KUBECONFIG}" == "" ]; then
  echo "ERROR: environment variable KUBECONFIG has not been set"; exit
fi

K8S_CONTEXT_CURRENT=$(kubectl config current-context)
if [ "${K8S_CONTEXT_CURRENT}" != "${TDH_TKGWC_NAME}-admin@${TDH_TKGWC_NAME}" ]; then 
  kubectl config use-context ${TDH_TKGWC_NAME}-admin@${TDH_TKGWC_NAME}
fi

# --- CHECK CLUSTER ---
stt=$(tkg get cluster $TDH_TKGWC_NAME -o json | jq -r --arg key $TDH_TKGWC_NAME '.[] | select(.name == $key).status')                            
if [ "${stt}" != "running" ]; then
  echo "ERROR: tkg cluster is not in 'running' status"
  echo "       => tkg get cluster $TDH_TKGWC_NAME --config=$TDHPATH/config/$TDH_TKGMC_CONFIG"; exit
fi


listDeployments() {
  printf "%-30s %-8s %-15s %-20s %-5s %s\n" "DEPLOYMENT" "CLOUD" "REGION" "MGMT-CLUSTER" "PLAN" "CONFIGURATION"
  echo "----------------------------------------------------------------------------------------------------------------"

  for deployment in $(ls -1 ${TDHPATH}/deployments/tkgmc*.cfg); do
    PCF_TILE_PKS_VERSION=""
    PCF_TILE_PAS_VERSION=""

    . $deployment

    dep=$(basename $deployment)

    if [ "$PCF_TILE_PKS_VERSION" != "" ]; then
      TILE="PKS $PCF_TILE_PKS_VERSION"
    else
      TILE="PAS $PCF_TILE_PAS_VERSION"
    fi

    printf "%-30s %-8s %-15s %-20s %-5s %s\n" $dep $TDH_TKGMC_INFRASTRUCTURE $TDH_TKGMC_REGION $TDH_TKGMC_NAME \
           $TDH_TKGMC_PLAN "$TDH_TKGMC_CONFIG"
  done

  echo "----------------------------------------------------------------------------------------------------------------"
}


variable_notice() {
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please set the missing environment variables either in your shell or in the pcfconfig"
  echo "             configuration file ~/.pcfconfig and set all variables with the 'export' notation"
  echo "             ie. => export AZURE_PKS_TLS_CERTIFICATE=/home/demouser/certs/cert.pem"
  echo "  --------------------------------------------------------------------------------------------------------------"
  exit 1
}

usage() {
  echo ""
  echo "Usage: $0 <Docker|Harbor>"
  echo "                             |       |"
  echo "                             |       |_______  Hosted Harbor Registry (demo.goharbor.io)"
  echo "                             |_______________  Docker Hub Registry (index.docker.io)"
  echo ""
}

if [ "$#" -eq 0 ]; then
  usage; exit 0
fi

