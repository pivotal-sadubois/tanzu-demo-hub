#!/bin/bash
# ============================================================================================
# File: ........: tce-cleanup.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Delete all temporary files, and docker container 
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

if [ -d /home/tanzu/.kube-tkg/tmp ]; then 
  rm -rf /home/tanzu/.kube-tkg/tmp
fi

if [ -f $HOME/.config/tanzu/config.yaml ]; then 
  rm -f $HOME/.config/tanzu/config.yaml 
fi

if [ -f $HOME/.tanzu/config.yaml ]; then 
  rm -f $HOME/.tanzu/config.yaml 
fi

docker kill $(docker ps -q)
docker system prune -a --volumes -f

