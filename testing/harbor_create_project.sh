# ############################################################################################
# File: ........: gitea_create_org.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Create a Gitea Organisation
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

if [ "$1" == "" ]; then
  echo "Usage: $0 <gitea-repository>"
  exit 1
else
  HARBOR_PROJECT=$1
fi

. ../functions
. $HOME/.tanzu-demo-hub.cfg


createHarborProject $HARBOR_PROJECT
