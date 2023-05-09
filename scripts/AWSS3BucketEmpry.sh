#!/bin/bash
# ============================================================================================
# File: ........: AWSS3BucketEmpty.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Upload files to the tanzu-demo-hub S3 Bucket (works only for Sacha Dubois)
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

BUCKET=$1

if [ "$BUCKET" == "" ]; then 
  echo "USAGE: $0 [aws-s3-bucket]
  echo "       aws-s3-bucket"
  echo "           - s3://tdh-tap-tech-docs  ## Tanzu Demo Hub - TechDocs"
  exit 0
fi

. ~/.tanzu-demo-hub.cfg

export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
export AWS_DEFAULT_REGION=$AWS_REGION

echo "------------------------------------------------------------------------------------------------------------"
for n in $(aws s3 ls $BUCKET | awk '{ print $NF }'); do

  aws s3 rm --recursive --recursive $BUCKET/$n

done
