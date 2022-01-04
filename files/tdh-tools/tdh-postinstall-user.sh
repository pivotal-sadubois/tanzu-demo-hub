#!/bin/bash

if [ ! -d $HOME/.tanzu ]; then 
  cd /tanzu && tanzu plugin clean
  cd /tanzu && tanzu plugin install --local cli all
fi

exit 0
