#!/bin/bash
# ############################################################################################
# File: ........: tdh-demo-selftest.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Deploy TKG Management Cluster
# ############################################################################################

#!/bin/bash

export TDH_DEMO_DIR="tanzu-data-postgres"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*$TDH_DEMO_DIR\).*+\1+g")
export NAMESPACE="tanzu-data-postgres-demo"
export TDHDEMO_ABORT_ON_FAILURE=1
export TDHDEMO_SHOW_HEADER=1
export DEBUG=0
export OPTIONS=""

printLine() {
  if [ $DEBUG -eq 1 ]; then 
    echo "----------------------------------------------------------------------------------------------------------------------------------------"
  else
    echo "-----------------------------------------------------------------------------------------------------------"
  fi
}

usage() {
  echo "USAGE: $0 [oprions] <deployment>"
  echo "                   --clean/-c   # Clean previous installation and stop the jump server"
  echo "                   --debug/-d   # Enable debugging"
}

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --no_abort_on_failure)  TDHDEMO_ABORT_ON_FAILURE=0;;
    --no_header)            TDHDEMO_SHOW_HEADER=0;;
    --debug)                DEBUG=1; OPTIONS="--debug";;
  esac
  shift
done

if [ $TDHDEMO_SHOW_HEADER -eq 1 ]; then
  echo ""
  echo "Tanzu Demo Hub - Demo Self Testing Suite"
  echo "by Sacha Dubois, VMware Inc,"
  printLine
fi

if [ -f .selftest ]; then 
  for subdemo in $(ls -1 demos/${demo}/.selftest/* 2>/dev/null); do
    $subdemo $OPTIONS
  done
fi

exit

for demo in $(ls -1 demos); do
  messageTitle "Testing Demo ($demo)" 
  if [ -d demos/${demo}/.selftest ]; then  
    for subdemo in $(ls -1 demos/${demo}/.selftest/* 2>/dev/null); do
      $subdemo --no_abort_on_failure $OPTIONS
    done
  fi
  break
done


