#!/bin/bash

if [ $(stat -c "%U" $HOME/.ssh) == "root" ]; then
  echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  echo "## Cleaning leftover local directories from other versions of the-tools"
  rm -rf $HOME/.local/* $HOME/.tanzu/* $HOME/.kube/* 2>/dev/null
  echo "## Recursivly changing ownership of '$HOME' to user and group 'tanzu'" 
  chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1
fi

# --- ACCEPT EULA ---
tanzu config eula accept > /dev/null 2>&1

# --- INSTALL TAP PLUGINS ---
if [ ! -d $HOME/.local/share/tanzu-cli/management-cluster ]; then 
  echo "## Installing tanzu-tkg cli plugins, this may take a while ..."
  cnt=0; ret=1
  while [ ${ret} -ne 0 -a ${cnt} -lt 3 ]; do
    tanzu plugin install --group vmware-tkg/default 2>/dev/null; ret=$?
    [ $ret -eq 0 ] && break
    cnt=cnt+1
  done
fi

# --- INSTALL TAP PLUGINS ---
if [ ! -d $HOME/.local/share/tanzu-cli/services ]; then 
  echo "## Installing tanzu-tap v1.6.1 cli plugins, this may take a while ..."
  cnt=0; ret=1
  while [ ${ret} -ne 0 -a ${cnt} -lt 3 ]; do
    tanzu plugin install --group vmware-tap/default:v1.6.1 2>/dev/null; ret=$?
    [ $ret -eq 0 ] && break
    cnt=cnt+1
  done
fi

cnt=0; ret=1
while [ ${ret} -ne 0 -a ${cnt} -lt 3 ]; do
  tanzu plugin sync; ret=$?
  [ $ret -eq 0 ] && break
  let cnt=cnt+1
done

