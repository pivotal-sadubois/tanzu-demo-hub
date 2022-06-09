#!/bin/bash
# ============================================================================================
# File: ........: AWSS3BucketUpload.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Upload files to the tanzu-demo-hub S3 Bucket (works only for Sacha Dubois)
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

TDH_TOOLS_NAME=$1

if [ "$TDH_TOOLS_NAME" == "" ]; then 
  echo "USAGE: $0 [tdh-tools-tkg-1.x.y]"
  exit 0
fi

if [ ! -f $HOME/.tanzu-demo-hub/cache/tdh-tools/${TDH_TOOLS_NAME}.tar ]; then 
  echo "ERROR: tdh-tools container: $HOME/.tanzu-demo-hub/cache/tdh-tools/${TDH_TOOLS_NAME}.tar does not exist"
  exit
fi

. ~/.tanzu-demo-hub.cfg

export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
export AWS_DEFAULT_REGION=$AWS_REGION

aws s3 cp $HOME/.tanzu-demo-hub/cache/tdh-tools/${TDH_TOOLS_NAME}.tar s3://tanzu-demo-hub
aws s3 cp $HOME/.tanzu-demo-hub/cache/tdh-tools/${TDH_TOOLS_NAME}.sum s3://tanzu-demo-hub
aws s3 cp $HOME/.tanzu-demo-hub/cache/tdh-tools/${TDH_TOOLS_NAME}.tag s3://tanzu-demo-hub
echo "------------------------------------------------------------------------------------------------------------"
aws s3 ls tanzu-demo-hub
