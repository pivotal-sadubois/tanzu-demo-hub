#!/bin/bash

if [ $(stat -c "%U" $HOME/.ssh) == "root" ]; then
  echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  echo "## Cleaning leftover local directories from other versions of the-tools"
  rm -rf $HOME/.local/* $HOME/.tanzu/* $HOME/.kube/* 2>/dev/null
  echo "## Recursivly changing ownership of '$HOME' to user and group 'tanzu'" 
  chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1
fi

# -- TANZU CLI INIT ---
if [ ! -d $HOME/.local/share/tanzu-cli/pinniped-auth ]; then
  echo "## Initial Configuration of Tanzu CLI"
  tanzu init 
fi

tap_plugins_installed=1
for plugin in $(ls -1 /tanzu-tap/cli/distribution/linux/amd64/cli); do [ ! -d $HOME/.local/share/tanzu-cli/$plugin ] && tap_plugins_installed=0; done
if [ $tap_plugins_installed -eq 0 ]; then 
  echo "## Install Tanzu Application Platform (TAP) CLI Plugins"
  for plugin in $(ls -1 /tanzu-tap/cli/distribution/linux/amd64/cli); do 
    [ ! -d $HOME/.local/share/tanzu-cli/$plugin ] && cd /tanzu-tap && tanzu plugin install --local cli $plugin
  done
fi
