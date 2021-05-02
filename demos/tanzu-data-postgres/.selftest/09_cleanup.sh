#!/bin/bash

export TDHDEMO=$(cd "$(pwd)/$(dirname $0)/.."; pwd)
export TDHHOME=$(cd "$(pwd)/$(dirname $0)/../../.."; pwd)
export NAMESPACE="tanzu-data-postgres-demo"
export TDHDEMO_ABORT_ON_FAILURE=1
export DEBUG=0
export first=1

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

while [ "$1" != "" ]; do
  case $1 in
    --no_abort_on_failure)  TDHDEMO_ABORT_ON_FAILURE=0;;
    --debug)                DEBUG=1;;
  esac
  shift
done

#########################################################################################################################
########################## TANZU DATA FOR POSTGRESS - POSTGRES BACKUP AND RESTORE DEMO ##################################
#########################################################################################################################

selfTestInit "Tanzu Data for Postgres - Cleaning up Demo Environment in Namespace $NAMESPACE" 1
selfTestStep "kubectl delete ns $NAMESPACE"
selfTestFine

exit 0
