#!/bin/bash

/usr/local/bin/tanzu > /dev/null 2>&1; ret=$?

#if [ ! -f $HOME/.tanzu/config.yaml ]; then 
if [ $ret -ne 0 ]; then 
  # --- INSTALL TANZU UTILITIES ---
  /tanzu/tce-linux-amd64/install.sh 
  #cd /tanzu/tce-linux-amd64 && tanzu plugin clean                                                               <
  #cd /tanzu/tce-linux-amd64 && tanzu plugin install --local cli all  
fi

exit 0
