#!/bin/bash

if [ ! -x /usr/local/bin/tanzu ]; then 
  # --- INSTALL TANZU UTILITIES ---
  cd /tanzu/tce-linux-amd64 && nohup ./install.sh > /dev/null 2>&1
  #cd /tanzu/tce-linux-amd64 && tanzu plugin clean                                                               <
  #cd /tanzu/tce-linux-amd64 && tanzu plugin install --local cli all  
fi

exit 0
