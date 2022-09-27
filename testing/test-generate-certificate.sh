#!/bin/bash
# ############################################################################################
# File: ........: test-generate-certificate.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test Certificate Generation through cert-manager
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

. ../functions
. $HOME/.tanzu-demo-hub.cfg

NAMESPACE=tdh-certificate
TDH_ENVNAME=awspas
TDH_TLS_ISSUER_NAME=letsencrypt-staging
TDH_TLS_CERT=tanzu-demo-hub
TDH_TLS_SECRET=${TDH_TLS_CERT}-tls

deleteNamespace $NAMESPACE > /dev/null 2>&1
createNamespace $NAMESPACE > /dev/null 2>&1

# --- CLEANUP ---
cmdLoop kubectl delete clusterissuer $TDH_TLS_ISSUER_NAME > /dev/null 2>&1
cmdLoop kubectl delete secret tanzu-demo-hub-tls -n default > /dev/null 2>&1
cmdLoop kubectl -n cert-manager delete secret route53-credentials-secret > /dev/null 2>&1

LETSENSCRIPT_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"   ## TESING
#LETSENSCRIPT_SERVER="https://acme-v02.api.letsencrypt.org/directory"          ## PRODUCTION

cmdLoop aws route53 list-hosted-zones-by-name --dns-name ${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN} > /tmp/output.json
AWS_HOSTED_ZONE=$(jq -r ".HostedZones[] | select(.Name | scan(\"^${zone}.\")).Id" /tmp/output.json)
cmdLoop aws route53 list-hosted-zones --output json > /tmp/output.json

AWS_HOSTED_ZONE_ID=$(jq -r --arg key "${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}." '.HostedZones[] | select(.Name == $key).Id' /tmp/output.json | \
                         awk -F '/' '{ print $NF }')

# --- DELETE LEFTOVER LETSENSCRIPT (ACME) ENTRIES ---
cmdLoop aws route53 list-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID > /tmp/output.json

for n in $(jq -r '.ResourceRecordSets[] | select(.Name | contains("_acme")).Name' /tmp/output.json 2>/dev/null); do
  ttl=$(jq -r --arg key "$n" '.ResourceRecordSets[] | select(.Name == $key).TTL' /tmp/output.json | sed 's/"//g')  
  ttt=$(jq -r --arg key "$n" '.ResourceRecordSets[] | select(.Name == $key).Type' /tmp/output.json | sed 's/"//g')  
  rrc=$(jq -r --arg key "$n" '.ResourceRecordSets[] | select(.Name == $key).ResourceRecords[].Value' /tmp/output.json | sed 's/"//g')  

  TMPROUTE53=/tmp/tmp_route53.json
  echo "{"                                                   >  $TMPROUTE53
  echo "  \"Comment\": \"CREATE/DELETE/UPSERT a record \","  >> $TMPROUTE53
  echo "  \"Changes\": [{"                                   >> $TMPROUTE53
  echo "  \"Action\": \"DELETE\","                           >> $TMPROUTE53
  echo "  \"ResourceRecordSet\": {"                          >> $TMPROUTE53
  echo "    \"Name\": \"${n}\","                             >> $TMPROUTE53
  echo "    \"Type\": \"$ttt\","                             >> $TMPROUTE53
  echo "    \"TTL\": $ttl,"                                  >> $TMPROUTE53
  echo "    \"ResourceRecords\": [ "                         >> $TMPROUTE53
  echo "      { \"Value\": \"\\\"${rrc}\\\"\" }"             >> $TMPROUTE53
  echo "    ]"                                               >> $TMPROUTE53
  echo "}}]"                                                 >> $TMPROUTE53
  echo "}"                                                   >> $TMPROUTE53

  cmdLoop aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch file://${TMPROUTE53} > /tmp/error.log 2>&1; ret=$?

  if [ $ret -ne 0 ]; then
    logMessages /tmp/error.log
    echo "ERROR: failed to delete leftover '_acme' challange records in AWS Route53"
    if [ "$NATIVE" == "0" ]; then
      echo "       => tools/${TDH_TOOLS}.sh"
      echo "          tdh-tools:/$ cat $TMPROUTE53
      echo "          tdh-tools:/$ aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch file://${TMPROUTE53}"
      echo "          tdh-tools:/$ exit"
    else
      echo "       => cat $TMPROUTE53
      echo "       => aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch file://${TMPROUTE53}"
    fi
    exit 1
  fi

done

TDH_TLS_ISSUER_FILE=/tmp/clusterissuer.yaml
echo "apiVersion: cert-manager.io/v1"                                          >  $TDH_TLS_ISSUER_FILE
echo "kind: ClusterIssuer"                                                     >> $TDH_TLS_ISSUER_FILE
echo "metadata:"                                                               >> $TDH_TLS_ISSUER_FILE
echo "  name: $TDH_TLS_ISSUER_NAME"                                            >> $TDH_TLS_ISSUER_FILE
echo "  namespace: $NAMESPACE"                                                 >> $TDH_TLS_ISSUER_FILE
echo "spec:"                                                                   >> $TDH_TLS_ISSUER_FILE
echo "  acme:"                                                                 >> $TDH_TLS_ISSUER_FILE
echo "    email: $TDH_CERTMANAGER_EMAIL"                                       >> $TDH_TLS_ISSUER_FILE
echo "    privateKeySecretRef:"                                                >> $TDH_TLS_ISSUER_FILE
echo "      name: $TDH_TLS_ISSUER_NAME"                                        >> $TDH_TLS_ISSUER_FILE
echo "    server: $LETSENSCRIPT_SERVER"                                        >> $TDH_TLS_ISSUER_FILE
echo "    solvers:"                                                            >> $TDH_TLS_ISSUER_FILE
echo "    - selector:"                                                         >> $TDH_TLS_ISSUER_FILE
echo "        dnsZones:"                                                       >> $TDH_TLS_ISSUER_FILE
echo "          - \"*.apps-contour.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""  >> $TDH_TLS_ISSUER_FILE
echo "          - \"*.apps-nginx.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""    >> $TDH_TLS_ISSUER_FILE
echo "          - \"*.gitlab.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""        >> $TDH_TLS_ISSUER_FILE
echo "          - \"*.cnrs.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""          >> $TDH_TLS_ISSUER_FILE
echo "          - \"learningcenter.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""  >> $TDH_TLS_ISSUER_FILE
echo "          - \"tap-gui.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}\""         >> $TDH_TLS_ISSUER_FILE
echo "      dns01:"                                                            >> $TDH_TLS_ISSUER_FILE
echo "        route53:"                                                        >> $TDH_TLS_ISSUER_FILE
echo "          region: $AWS_REGION"                                           >> $TDH_TLS_ISSUER_FILE
echo "          accessKeyID: $AWS_CERT_ACCESS_KEY"                             >> $TDH_TLS_ISSUER_FILE
echo "          secretAccessKeySecretRef:"                                     >> $TDH_TLS_ISSUER_FILE
echo "            name: route53-credentials-secret"                            >> $TDH_TLS_ISSUER_FILE
echo "            key: aws-credentials"                                        >> $TDH_TLS_ISSUER_FILE
echo "          hostedZoneID: $AWS_HOSTED_ZONE_ID"                             >> $TDH_TLS_ISSUER_FILE

CERTIFICATE_CONFIG=/tmp/certificate_request.yaml
echo "apiVersion: cert-manager.io/v1"                                          >  $CERTIFICATE_CONFIG
echo "kind: Certificate"                                                       >> $CERTIFICATE_CONFIG
echo "metadata:"                                                               >> $CERTIFICATE_CONFIG
echo "  name: $TDH_TLS_CERT"                                                   >> $CERTIFICATE_CONFIG
echo "spec:"                                                                   >> $CERTIFICATE_CONFIG
echo "  secretName: $TDH_TLS_SECRET"                                           >> $CERTIFICATE_CONFIG
echo "  issuerRef:"                                                            >> $CERTIFICATE_CONFIG
echo "    name: letsencrypt-staging"                                           >> $CERTIFICATE_CONFIG
echo "    kind: ClusterIssuer"                                                 >> $CERTIFICATE_CONFIG
echo "  dnsNames:"                                                             >> $CERTIFICATE_CONFIG
echo "  - '*.apps-contour.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"            >> $CERTIFICATE_CONFIG
echo "  - '*.apps-nginx.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"              >> $CERTIFICATE_CONFIG
echo "  - '*.gitlab.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"                  >> $CERTIFICATE_CONFIG
echo "  - '*.cnrs.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"                    >> $CERTIFICATE_CONFIG
echo "  - 'learningcenter.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"            >> $CERTIFICATE_CONFIG
echo "  - 'tap-gui.${TDH_ENVNAME}.${AWS_HOSTED_DNS_DOMAIN}'"                   >> $CERTIFICATE_CONFIG

echo "$AWS_CERT_SECRET_KEY" > /tmp/aws-credentials
kubectl -n cert-manager create secret generic route53-credentials-secret \
        --from-file=aws-credentials=/tmp/aws-credentials

echo "TDH_TLS_ISSUER_FILE:$TDH_TLS_ISSUER_FILE"
echo "CERTIFICATE_CONFIG:$CERTIFICATE_CONFIG"
kubectl -n $NAMESPACE apply -f $TDH_TLS_ISSUER_FILE

sleep 60 
kubectl -n $NAMESPACE create -f $CERTIFICATE_CONFIG

# --- COPY SECRET TO NAMESPACE ---
messagePrint " ▪ Copy TLS Secre from $NAMESPACEt to default" "tanzu-demo-hub-tls"
copySecretObject $NAMESPACE default tanzu-demo-hub-tls

echo "kubectl -n cert-manager logs cert-manager-59787bb745-pppbq"
echo "vi /tmp/letsencrypt-staging"
echo "kubectl -n $NAMESPACE get clusterissuer"
echo "kubectl -n $NAMESPACE get order -A"
echo "kubectl -n $NAMESPACE get challenge -A"
echo "kubectl -n $NAMESPACE get certificate -A"
echo "kubectl -n $NAMESPACE get certificaterequest -A"
echo "kubectl -n $NAMESPACE get event"

