#!/bin/bash
# ============================================================================================
# File: ........: AWSS3TapTechDocs.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Upload files to the tanzu-demo-hub S3 Bucket (works only for Sacha Dubois)
# ============================================================================================
[ "$(hostname)" == "tdh-tools" ] && echo "ERROR: Need to run outside a tdh-tools container" && exit

TDHPATH=$(cd "$(pwd)/$(dirname $0)"; pwd)
TDH_TOOLS_NAME=$1

if [ "$TDH_TOOLS_NAME" == "" ]; then 
  echo "USAGE: $0 [git-repository]"
  echo "           git-repository"
  echo "                 - https://github.com/tsalm-pivotal/spring-cloud-demo-tap"
  echo "                 - https://github.com/dambor/yelb-catalog"
  echo "                 - https://github.com/dambor/blank"
  echo "                 - https://github.com/pivotal-sadubois/blockchain-api"
  echo "                 - https://github.com/pivotal-sadubois/newsletter"
  exit 0
fi

# --- LOAD TDH CONFIGURATION AND FUNCTIONS ---
[ -f $TDHPATH/../functions ] && . $TDHPATH/../functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

pip -q install --upgrade pip
pip -q install npx
pip -q install mkdocs
pip -q install mkdocs-techdocs-core

checkTDHsettings techdoc

GIT_TMPREPO=/tmp/tech_docs
GIT_TMPSITE=/tmp/tech_site
GIT_REPONAM=$1
GIT_REPODIR=$(echo $1 | awk -F'/' '{ print $NF }') 

[ -d $GIT_TMPREPO ] && rm -rf $GIT_TMPREPO; mkdir -p $GIT_TMPREPO
[ -d $GIT_TMPSITE ] && rm -rf $GIT_TMPSITE; mkdir -p $GIT_TMPSITE

git -C $GIT_TMPREPO clone $GIT_REPONAM; ret=$? 
if [ $ret -ne 0 ]; then 
  echo "ERROR: failed to clone repo $GIT_REPONAM"; exit 1
fi

CATALOG_INFO=$(find $GIT_TMPREPO -name catalog-info.yaml | head -1)
echo "CATALOG_PATH:$CATALOG_PATH"
if [ "$CATALOG_INFO" != "" ]; then 
  CATALOG_PATH=$(dirname $CATALOG_INFO)
else
  echo "ERROR: failed to find a catalog-info.yaml in $GIT_TMPREPO"
fi

CATALOG_KIND=$(yq -o=json $CATALOG_INFO | jq -r '.kind') 
CATALOG_NMSP=$(yq -o=json $CATALOG_INFO | jq -r '.metadata.namespace') 
CATALOG_NAME=$(yq -o=json $CATALOG_INFO | jq -r '.metadata.name') 
[ "$CATALOG_NMSP" == "" -o "$CATALOG_NMSP" == "null" ] && CATALOG_NMSP="default"

if [ "$AWS_S3_TECHDOC_BUCKET" == "" ]; then 
  echo "ERROR: AWS S3 Bucket: AWS_S3_TECHDOC_BUCKET not configured in ~/.tanzu-demo-hub-techdocs.cfg"; exit
fi

# --- AWS ADMIN SECRETS ---
export AWS_ACCESS_KEY_ID=$AWS_S3_TECHDOC_UPLOAD_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_S3_TECHDOC_UPLOAD_SECRET_KEY
export AWS_REGION=$AWS_S3_TECHDOC_BUCKET_REGION

echo "export AWS_ACCESS_KEY_ID=$AWS_S3_TECHDOC_UPLOAD_ACCESS_KEY"
echo "export AWS_SECRET_ACCESS_KEY=$AWS_S3_TECHDOC_UPLOAD_SECRET_KEY"
echo "export AWS_S3_TECHDOC_BUCKET=$AWS_S3_TECHDOC_BUCKET"
echo "export AWS_REGION=$AWS_S3_TECHDOC_BUCKET_REGION"


echo "npx @techdocs/cli generate --source-dir $CATALOG_PATH --output-dir $GIT_TMPSITE" --no-docker >  /tmp/tech.txt
npx @techdocs/cli generate --source-dir $CATALOG_PATH --output-dir $GIT_TMPSITE --no-docker 2>/dev/null; ret=$?
if [ $ret -ne 0 ]; then
  echo "ERROR: failed to generate the TechDocs for the catalog root"
  echo " => npx @techdocs/cli generate --source-dir $CATALOG_INFO --output-dir $GIT_TMPSITE --no-docker"; exit
fi

echo "npx @techdocs/cli publish --publisher-type awsS3 --storage-name $AWS_S3_TECHDOC_BUCKET --entity $CATALOG_NMSP/$CATALOG_KIND/$CATALOG_NAME --directory $GIT_TMPSITE" >> /tmp/tech.txt
npx @techdocs/cli publish --publisher-type awsS3 --storage-name $AWS_S3_TECHDOC_BUCKET --entity $CATALOG_NMSP/$CATALOG_KIND/$CATALOG_NAME --directory $GIT_TMPSITE 2>/dev/null; ret=$?
if [ $ret -ne 0 ]; then 
  echo "ERROR: failed to Publish documentation"
  echo " => npx @techdocs/cli publish --publisher-type awsS3 --storage-name $AWS_S3_TECHDOC_BUCKET --entity $CATALOG_NMSP/$CATALOG_KIND/$CATALOG_NAME --directory $GIT_TMPSITE"; exit
  exit
fi

echo "---------------------------------------------------------------------------------------------------------------------"
for n in $(yq -o=json $CATALOG_INFO | jq -r '.spec.targets[]'); do
  TARGET_PATH=$(dirname $CATALOG_PATH/$n) 

  TARGET_KIND=$(yq -o=json $CATALOG_PATH/$n | jq -r '.kind' | head -1)
  TARGET_NMSP=$(yq -o=json $CATALOG_PATH/$n | jq -r '.metadata.namespace' | head -1)  
  TARGET_NAME=$(yq -o=json $CATALOG_PATH/$n | jq -r '.metadata.name' | head -1)
  [ "$TARGET_NMSP" == "" -o "$TARGET_NMSP" == "null" ] && TARGET_NMSP="default"

  echo "=> Generating: $n $CATALOG_PATH"
echo "npx @techdocs/cli generate --source-dir $TARGET_PATH --output-dir $GIT_TMPSITE" >> /tmp/tech.txt
  npx @techdocs/cli generate --source-dir $TARGET_PATH/ --output-dir $GIT_TMPSITE 2>/dev/null | sed 's/^/   /g'

  echo "=> Processing: $n ($TARGET_NMSP/$TARGET_KIND/$TARGET_NAME) $TARGET_PATH"
echo "npx @techdocs/cli publish \
      --publisher-type awsS3 \
      --storage-name $AWS_S3_TECHDOC_BUCKET \
      --entity $TARGET_NMSP/$TARGET_KIND/$TARGET_NAME \
      --directory $GIT_TMPSITE" >> /tmp/tech.txt

  npx @techdocs/cli publish \
      --publisher-type awsS3 \
      --storage-name $AWS_S3_TECHDOC_BUCKET \
      --entity $TARGET_NMSP/$TARGET_KIND/$TARGET_NAME \
      --directory $GIT_TMPSITE 2>/dev/null | sed 's/^/   /g'

  echo ""
done
exit

