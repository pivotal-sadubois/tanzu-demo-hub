#!/bin/bash

chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1

#export TANZU_CLI_NO_INIT=true
[ ! -d $HOME/.local/share/tanzu-cli/management-cluster ] && /usr/local/bin/tanzu plugin sync > /dev/null 2>&1
[ ! -d $HOME/.local/share/tanzu-cli/accelerator ] && cd /tanzu-tap && tanzu plugin install --local cli all > /dev/null 2>&1
