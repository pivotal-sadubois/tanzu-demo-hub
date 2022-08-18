# ############################################################################################
# File: ........: gitea_create_repo.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Create a Gitea Repository
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

if [ "$1" == "" ]; then
  echo "Usage: $0 <gitea-organisatino> <gitea-repository>"
  exit 1
else
  GITEA_ORGANISATION=$1
  GITEA_REPOSITORY=$2
fi

. ../functions
. $HOME/.tanzu-demo-hub.cfg

createGiteaOrg  $GITEA_ORGANISATION
createGiteaRepo $GITEA_ORGANISATION $GITEA_REPOSITORY

