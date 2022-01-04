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
  tdh_tools_build tce
  checkExecutionLock tdh-tools
fi

if [ $? -ne 0 ]; then 
  echo "ERROR: $0 is already running, plese stop it first"
  exit 1
fi

# --- DUMP ENVIRONMENT VARIABLES ---
env | grep TDH > /tmp/tdh.env

if [ $ROOT_SHELL -eq 0 ]; then 
  #docker run -it --rm --name tdh-tools-tce -v /var/run/docker.sock:/var/run/docker.sock tdh-tools-tce:latest chmod 666 /var/run/docker.sock > /dev/null 2>&1
  #docker run -it --init --rm --name tdh-tools-tce -v /var/run/docker.sock:/var/run/docker.sock tdh-tools-tce:latest chmod 666 /var/run/docker.sock 
  docker run -it --init --rm --name tdh-tools-tce -v /var/run/docker.sock:/var/run/docker.sock tdh-tools-tce:latest /usr/local/bin/tdh-postinstall-root.sh > /dev/null 2>&1
  docker run -u $(id -u):$(id -g) -it --init --rm --name tdh-tools-tce --network=host --env-file /tmp/tdh.env \
     -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools-tce:latest $COMMAND

#     -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
#     -v $HOME/.config:$HOME/.config:rw -v $HOME/.config_tools/tanzu:$HOME/.config/tanzu:rw\
#     -v $HOME/.kube-tkg:$HOME/.kube-tkg:rw -v $HOME/.kube:$HOME/.kube:rw -v $HOME/.govmomi:$HOME/.govmomi:rw \
#     -v $HOME/.ssh:$HOME/.ssh:rw -v $HOME/.terraform:$HOME/.terraform:rw -v $HOME/.gradle:$HOME/.gradle:rw \
#     -v $HOME/.s3cfg:$HOME/.s3cfg:rw -v $HOME/.local_tools:$HOME/.local:rw \
#     -v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
#     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw \
#     -v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
#  docker run --network=host -u $(id -u):$(id -g) -it --rm --name tdh-tools-tce --env-file /tmp/tdh.env \
#     -v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
#     -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:$HOME/.cache:rw -v $HOME/.config:$HOME/.config:rw \
#     -v $HOME/.aws:$HOME/.aws:rw -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
#     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw -v $HOME/.tanzu:$HOME/.tanzu:rw \
#     -v $HOME/.kube-tkg:$HOME/.kube-tkg:rw -v $HOME/.kube:$HOME/.kube:rw -v $HOME/.govmomi:$HOME/.govmomi:rw \
#     -v $HOME/.ssh:$HOME/.ssh:rw -v $HOME/.terraform:$HOME/.terraform:rw -v $HOME/.gradle:$HOME/.gradle:rw \
#     -v $HOME/.s3cfg:$HOME/.s3cfg:rw \
#     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools-tce:latest $COMMAND
else
  docker run -it --rm --name tdh-tools-tce -v /var/run/docker.sock:/var/run/docker.sock tdh-tools-tce:latest  chmod 666 /var/run/docker.sock > /dev/null 2>&1
  docker run -it --rm --name tdh-tools-tce --env-file /tmp/tdh.env \
     -v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:$HOME/.cache:rw -v $HOME/.config:$HOME/.config:rw \
     -v $HOME/.aws:$HOME/.aws:rw -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw -v $HOME/.tanzu:$HOME/.tanzu:rw \
     -v $HOME/.kube-tkg:$HOME/.kube-tkg:rw -v $HOME/.kube:$HOME/.kube:rw -v $HOME/.govmomi:$HOME/.govmomi:rw \
     -v $HOME/.ssh:$HOME/.ssh:rw -v $HOME/.terraform:$HOME/.terraform:rw -v $HOME/.gradle:$HOME/.gradle:rw \
     -v $HOME/.s3cfg:$HOME/.s3cfg:rw \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools-tce:latest $COMMAND
fi

exit


