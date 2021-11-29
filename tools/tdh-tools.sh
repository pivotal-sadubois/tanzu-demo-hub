#!/bin/bash
# ############################################################################################
# File: ........: tdh-tools.sh
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
  tdh_tools_build > /dev/null 2>&1
  checkExecutionLock tdh-tools > /dev/null 2>&1
else
  echo ""
  echo "Tanzu Demo Hub - TDH Tools Docker Container"
  echo "by Sacha Dubois, VMware Inc,"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo ""

  tdh_tools_build
  checkExecutionLock tdh-tools
fi

if [ $? -ne 0 ]; then 
  echo "ERROR: $0 is already running, plese stop it first"
  exit 1
fi

# --- DUMP ENVIRONMENT VARIABLES ---
env | grep TDH > /tmp/tdh.env

# /Users/sdu/.tanzu/config.yaml
# /Users/sdu/.config/tanzu/config.yaml

if [ $ROOT_SHELL -eq 0 ]; then 
  [ ! -d $HOME/.tanzu ] && mkdir -p $HOME/.tanzu

  docker run -it --rm --name tdh-tools -v /var/run/docker.sock:/var/run/docker.sock tdh-tools:latest  chmod 666 /var/run/docker.sock > /dev/null 2>&1
  docker run -u $(id -u):$(id -g) -it --rm --name tdh-tools --env-file /tmp/tdh.env \
     -v $HOME:$HOME:ro -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v $HOME/.config:$HOME/.config:rw -v $HOME/.config_tools/tanzu:$HOME/.config/tanzu:rw\
     -v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw \
     -v $HOME/.kube-tkg:$HOME/.kube-tkg:rw -v $HOME/.kube:$HOME/.kube:rw -v $HOME/.govmomi:$HOME/.govmomi:rw \
     -v $HOME/.ssh:$HOME/.ssh:rw -v $HOME/.terraform:$HOME/.terraform:rw -v $HOME/.gradle:$HOME/.gradle:rw \
     -v $HOME/.s3cfg:$HOME/.s3cfg:rw -v $HOME/.local_tools:$HOME/.local:rw \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools:latest $COMMAND

     #-v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.config_tools:$HOME/.config:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
     #-v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.config_tools:$HOME/.config:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
     #-v $HOME/.tanzu_tools:$HOME/.tanzu:rw -v $HOME/.tanzu_tools:$HOME/.config:rw -v $HOME/.cache_tools:$HOME/.cache:rw \
     #-v $HOME:$HOME:ro -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     #-v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw $HOME/.cache/helm:$HOME/.cache/helm:rw \
     #-v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     #-v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw -v $HOME/.cache/helm:$HOME/.cache/helm:rw \
else
  docker run -it --rm --name tdh-tools -v /var/run/docker.sock:/var/run/docker.sock tdh-tools:latest  chmod 666 /var/run/docker.sock > /dev/null 2>&1
  docker run -it --rm --name tdh-tools --env-file /tmp/tdh.env \
     -v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:$HOME/.cache:rw -v $HOME/.config:$HOME/.config:rw \
     -v $HOME/.aws:$HOME/.aws:rw -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw -v $HOME/.tanzu:$HOME/.tanzu:rw \
     -v $HOME/.kube-tkg:$HOME/.kube-tkg:rw -v $HOME/.kube:$HOME/.kube:rw -v $HOME/.govmomi:$HOME/.govmomi:rw \
     -v $HOME/.ssh:$HOME/.ssh:rw -v $HOME/.terraform:$HOME/.terraform:rw -v $HOME/.gradle:$HOME/.gradle:rw \
     -v $HOME/.s3cfg:$HOME/.s3cfg:rw \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools:latest $COMMAND
fi

exit

ls -la ~/.tanzu ~/.config ~/.cache
ls -la ~/.tanzu_tools ~/.config_tools ~/.cache_tools

tanzu plugin list
tanzu plugin repo  add --local cli core
itanzu plugin repo  add --local cli

tanzu plugin install --local cli all
tanzu plugin list
tanzu plugin clean

sdu@tdh-tools:/tanzu$ tanzu plugin repo delete core
sdu@tdh-tools:/tanzu$ tanzu plugin repo delete tkg 
sdu@tdh-tools:/tanzu$ tanzu plugin repo list  

