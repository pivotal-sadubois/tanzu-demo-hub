#!/bin/bash
# ############################################################################################
# File: ........: tdh-tools-tce.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - TDH Tools Container
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
export ROOT_SHELL=0
export COMMAND=bash
export SILENT=0

. $TANZU_DEMO_HUB/functions

. ~/.tanzu-demo-hub.cfg

usage() {
  echo "USAGE: $0 [oprions] <deployment>"
  echo "                   --usage     # Show this info"
  echo "                   --help      # Show this info"
  echo "                   --root      # Get a Root Shell"
  echo "                   --debug     # Show Debugging information"
  echo "                   --cmd       # Execute a command"
  exit 
}

while [ "$1" != "" ]; do
  case $1 in
    --usage)  usage;;
    --help)   usage;;
    --root)   ROOT_SHELL=1;;
    --cmd)    COMMAND="$2";;
    --debug)  DEBUG=1;;
    --silent) SILENT=1;;
  esac
  shift
done

mkdir -p $HOME/.mc $HOME/.cache $HOME/.config $HOME/.local
mkdir -p /tmp/docker && chmod a+w /tmp/docker

if [ $SILENT -eq 1 ]; then 
  tdh_tools_build tce > /dev/null 2>&1
  checkExecutionLock tdh-tools > /dev/null 2>&1
else
  echo ""
  echo "Tanzu Demo Hub - TDH Tools Docker Container"
  echo "by Sacha Dubois, VMware Inc,"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo ""

  checkCLIcommands BASIC
  tdh_tools_build  tce
  checkExecutionLock tdh-tools
fi

if [ $? -ne 0 ]; then 
  echo "ERROR: $0 is already running, plese stop it first"
  exit 1
fi

# --- CLEAN OLD CONTAINERS ---
cid=$(docker ps -a | grep $TDH_TOOLS:latest | awk '{ print $1 }')
[ "$cid" != "" ] && for n in $cid; do docker rm $n -f > /dev/null 2>&1; done

# --- DUMP ENVIRONMENT VARIABLES ---
env | grep TDH > /tmp/tdh.env

TDH_TOOLS=tdh-tools-tce
TDH_TOOLS_PATH=".${TDH_TOOLS}"
CORE_OPTIONS="-it --init --rm --hostname tdh-tools --name $TDH_TOOLS --network=host"
USER_OPTIONS="$CORE_OPTIONS -u $(id -u):$(id -g) --env-file /tmp/tdh.env -e \"KUBECONFIG=$HOME/.kube/config\""
ROOT_OPTIONS="$CORE_OPTIONS --env-file /tmp/tdh.env -e \"KUBECONFIG=$HOME/.kube/config\""

CORE_MOUNTS=(
         "-v /var/run/docker.sock:/var/run/docker.sock"                           ## REQIORED FOR DOCKER
         "-v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw"
         "-v $HOME/.tanzu-demo-hub.cfg:$HOME/.tanzu-demo-hub.cfg:ro"
         "-v $HOME/$TDH_TOOLS_PATH/.cache:$HOME/.cache:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.config:$HOME/.config:rw"                      ## CONFIG FOR HELM AND TANZU
         "-v $HOME/$TDH_TOOLS_PATH/.kube:$HOME/.kube:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.kube-tkg:$HOME/.kube-tkg:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.local:$HOME/.local:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.tanzu:$HOME/.tanzu:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.terraform:$HOME/.terraform:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.terraform.d:$HOME/.terraform.d:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.s3cfg:$HOME/.s3cfg:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.govmomi:$HOME/.govmomi:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.gradle:$HOME/.gradle:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.docker:$HOME/.docker:rw"                      ## DOCKER LOGIN CREDENTIALS
         "-v $HOME/$TDH_TOOLS_PATH/.mvn:$HOME/.mvn:rw"
         "-v $HOME/$TDH_TOOLS_PATH/.aws:$HOME/.aws:rw"                            ## PERSISTANT AWS CREDENTIALS
         "-v $HOME/$TDH_TOOLS_PATH/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw"    ## TANZU MISSION CONTROL (TMC) LOGIN CREDENTIALS
         "-v $HOME/$TDH_TOOLS_PATH/tmp:/tmp:rw"                                   ## KEEP TEMP PERSISTENT
         "-v $TDHPATH/:$TDHPATH:ro"                                               ## TANZU-DEMO-HUB DIRECTORY
       ) 

# --- MAKE SURE DIRECTORIES ARE CREATED ---
for n in $(echo ${CORE_MOUNTS[*]} | sed 's/\-. //g'); do
  localdir=$(echo $n | awk -F: '{ print $1 }')
  [ $n == "/var/run/docker.sock" ] && continue
  [ ! -d $localdir -a ! -f $localdir ] && mkdir -p $localdir
done

[ $ROOT_SHELL -eq 0 ] && LOGIN_OPTION=$USER_OPTIONS || LOGIN_OPTION=$ROOT_OPTIONS
docker run $ROOT_OPTIONS ${CORE_MOUNTS[*]} tdh-tools-tce:latest chmod 666 /var/run/docker.sock > /dev/null 2>&1
docker run $USER_OPTIONS ${CORE_MOUNTS[*]} tdh-tools-tce:latest /usr/local/bin/tdh-postinstall-user-tce.sh > /dev/null 2>&1
docker run $LOGIN_OPTION ${CORE_MOUNTS[*]} tdh-tools-tce:latest $COMMAND

exit 0


