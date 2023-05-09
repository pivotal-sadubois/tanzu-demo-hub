#!/bin/bash
# ############################################################################################
# File: ........: tdh-tools-cleanup.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - TDH Tools Container Cleanup
# ############################################################################################

TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
TDHPATH=$(cd "$(pwd)/$(dirname $0)/../"; pwd)
VERSION=$(echo $0 | sed -e 's/^.*cleanup-//g' -e 's/\.sh//g') 
TYPE=$(echo $0 | sed -e 's/-cleanup//g' -e 's/\.sh//g' | awk -F'/' '{ print $NF }') 

# --- SOUTCE FOUNCTIONS AND USER ENVIRONMENT ---
[ -f $TANZU_DEMO_HUB/functions ] && . $TANZU_DEMO_HUB/functions

tdhHeader "Tanzu Demo Hub - TDH Tools Container Cleanup ($TYPE)"

echo "WARNING: This will cleanup the temporary files (dotfiles) of the TDH Tools Container ($TYPE)"
echo "         Access to all active Tanzu Demo Hub deployments will be lost. The files and"
echo "         directory will be recreated the next time $TYPE wil be restarted."
echo ""

if [ -d $HOME/.${TYPE} ]; then 
  file $HOME/.${TYPE}/.* | awk -F: '{ print $1 }' | sed 1,2d | sed 's/^/         => /g'
fi

echo ""
x=""
while [ "$x" != "y" -a "$x" != "n" ]; do
  echo -e "Are you shure to delete thous files <y/n> ?: \c"; read x
done

if [ "$x" != "y" ]; then 
  [ "${TYPE}" != "" -a "$HOME" != "" ] && rm -rf $HOME/.${TYPE}
fi



