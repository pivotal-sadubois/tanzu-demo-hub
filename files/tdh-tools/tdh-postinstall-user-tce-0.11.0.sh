#!/bin/bash

chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1

#if [ -d $HOME/.local/.local/share/tanzu-cli ]; then 
#  /usr/local/bin/tanzu plugin list > /dev/null 2>&1; ret=$?
#  stt=$(/usr/local/bin/tanzu plugin list -o json | jq -r '.[] | select(.name == "management-cluster").status') 
#  if [ $ret -ne 0 -o "$stt" == "not installed" ]; then 
#    # --- INSTALL TANZU UTILITIES ---
#    /usr/bin/nohup /tanzu/tce-linux-amd64/install.sh > /tmp/nohup.oout
#    #cd /tanzu/tce-linux-amd64 && tanzu plugin clean  
#    #cd /tanzu/tce-linux-amd64 && tanzu plugin install --local cli all  
#  fi
#else
#  # --- INSTALL TANZU UTILITIES ---
#  /usr/bin/nohup /tanzu/tce-linux-amd64/install.sh > /tmp/nohup.oout
#fi

#export TANZU_CLI_NO_INIT=true
[ ! -d $HOME/.local/share/tanzu-cli/management-cluster ] && /usr/local/bin/tanzu plugin sync > /dev/null 2>&1
[ ! -d $HOME/.local/share/tanzu-cli/accelerator ] && cd /tanzu-tap && tanzu plugin install --local cli all > /dev/null 2>&1

exit 0
