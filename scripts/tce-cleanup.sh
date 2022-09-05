#!/bin/bash
# ============================================================================================
# File: ........: tce-cleanup.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Delete all temporary files, and docker container 
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

if [ -d $HOME/.kube-tkg/config ]; then 
  rm -rf $HOME/.kube-tkg/config
fi

if [ -d $HOME/.kube-tkg/tmp ]; then 
  rm -rf $HOME/.kube-tkg/tmp
fi

if [ -f $HOME/.config/tanzu/config.yaml ]; then 
  rm -f $HOME/.config/tanzu/config.yaml 
fi

if [ -f $HOME/.tanzu/config.yaml ]; then 
  rm -f $HOME/.tanzu/config.yaml 
fi

for n in $(docker ps  | grep -v tdh-tools | grep -v CONTAINER | awk '{ print $1 }'); do
  docker kill $n
done
docker system prune -a --volumes -f

