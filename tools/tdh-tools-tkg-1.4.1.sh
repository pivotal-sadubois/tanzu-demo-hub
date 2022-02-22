#!/bin/bash
# ############################################################################################
# File: ........: tdh-tools.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - TDH Tools Container
# ############################################################################################

export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
export ROOT_SHELL=0
export COMMAND=bash
export SILENT=0
export TDH_TOOLS=tdh-tools-tkg
export TKG_VERSION=1.4.1

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

while [ "$1" != "" ]; do
  case $1 in
    --usage)  usage;;
    --help)   usage;;
    --root)   ROOT_SHELL=1;;
    --cmd)    COMMAND="$2";;
    --debug)  DEBUG=1;;
    --silent) SILENT=1;;
    --version) VERSION=$2
  esac
  shift
done

#############################################################################################################################
################################### EXECUTING CODE WITHIN  TDH-TOOLS DOCKER CONTAINER  ######################################
#############################################################################################################################
runTDHtools tkg $TKG_VERSION "Run TDH Tools Docker Container" "bash" ""

usage() {
  echo "USAGE: $0 [oprions] <deployment>"
  echo "                   --usage     # Show this info"
  echo "                   --help      # Show this info"
  echo "                   --root      # Get a Root Shell"
  echo "                   --debug     # Show Debugging information"
  echo "                   --cmd       # Execute a command"
  exit
}

if [ $SILENT -eq 1 ]; then 
  tdh_tools_build    tkg > /dev/null 2>&1
  checkExecutionLock tdh-tools > /dev/null 2>&1
else
  echo ""
  echo "Tanzu Demo Hub - TDH Tools Docker Container"
  echo "by Sacha Dubois, VMware Inc,"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo ""

  checkCLIcommands   BASIC
  tdh_tools_build    tkg
  checkExecutionLock tdh-tools
fi

if [ $? -ne 0 ]; then 
  echo "ERROR: $0 is already running, plese stop it first"
  exit 1
fi

exit 0
