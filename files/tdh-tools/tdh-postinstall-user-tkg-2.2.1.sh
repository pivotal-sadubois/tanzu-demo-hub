#!/bin/bash

if [ $(stat -c "%U" $HOME/.ssh) == "root" ]; then
  echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  echo "## Cleaning leftover local directories from other versions of the-tools"
  rm -rf $HOME/.local/* $HOME/.tanzu/* $HOME/.kube/* 2>/dev/null
  echo "## Recursivly changing ownership of '$HOME' to user and group 'tanzu'" 
  chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1
fi

