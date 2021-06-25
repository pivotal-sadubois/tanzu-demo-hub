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

. $TANZU_DEMO_HUB/functions

. ~/.tanzu-demo-hub.cfg

usage() {
  echo "USAGE: $0 [oprions] <deployment>"
  echo "                   --usage     # Show this info"
  echo "                   --help      # Show this info"
  echo "                   --root      # Get a Root Shell"
  echo "                   --debug     # Show Debugging information"
  exit 
}

echo ""
echo "Tanzu Demo Hub - TDH Tools Docker Container"
echo "by Sacha Dubois, VMware Inc,"
echo "-----------------------------------------------------------------------------------------------------------"

while [ "$1" != "" ]; do
  case $1 in
    --usage)  usage;;
    --help)   usage;;
    --root)   ROOT_SHELL=1;;
    --debug)  DEBUG=1;;
  esac
  shift
done

tdh_tools_build

mkdir -p $HOME/.mc $HOME/.cache $HOME/.config $HOME/.local
mkdir -p /tmp/docker && chmod a+w /tmp/docker
echo ""

#docker rmi tdh-tools:latest > /dev/null 2>&1

if [ $ROOT_SHELL -eq 0 ]; then 
  docker run -it --rm --name tdh-tools -v /var/run/docker.sock:/var/run/docker.sock tdh-tools:latest  chmod 666 /var/run/docker.sock > /dev/null 2>&1
  docker run -u $(id -u):$(id -g) -it --rm --name tdh-tools \
     -v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:$HOME/.cache:rw -v $HOME/.config:$HOME/.config:rw \
     -v $HOME/.aws:$HOME/.aws:rw -v $HOME/.vmware-cna-saas:$HOME/.vmware-cna-saas:rw -v $HOME/.azure:$HOME/.azure:rw \
     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw -v $HOME/.tanzu:$HOME/.tanzu:rw \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools:latest bash
else
  docker run -it --rm --name tdh-tools -v /var/run/docker.sock:/var/run/docker.sock tdh-tools:latest  chmod 666 /var/run/docker.sock > /dev/null 2>&1
  docker run -it --rm --name tdh-tools \
     -v $HOME:$HOME:ro -v $HOME/.local:$HOME/.local:rw -v $HOME/.tanzu-demo-hub:$HOME/.tanzu-demo-hub:rw \
     -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:$HOME/.cache:rw -v $HOME/.config:$HOME/.config:rw \
     -v $HOME/.aws:$HOME/.aws:rw \
     -v /tmp:/tmp:rw -v /tmp/docker:$HOME/.docker:rw -v $HOME/.mc:$HOME/.mc:rw \
     -e "KUBECONFIG=$HOME/.kube/config" --hostname tdh-tools tdh-tools:latest bash
fi

exit


