#!/bin/bash

DNS_HARBOR="harbor.apps-tdh-1.vstkg.pcfsdu.com"
DNS_NOTARY="notary.apps-tdh-1.vstkg.pcfsdu.com"
HARBOR_NAMESPACE=harbor
HARBOR_VALUES=/tmp/harbor-data-values.yaml
HARBOR_PASS=Password12345
HARBOR_TLS_SELFSIGN=true
HARBOR_TLS_SELFSIGN=false
TDHPATH=$HOME/icloud/Development/tanzu-demo-hub

if [ $HARBOR_TLS_SELFSIGN == "true" ]; then 
  HARBOR_TLS_CERT=Harbor.apps-tdh-1.vstkg.pcfsdu.com+1.pem
  HARBOR_TLS_KEY=harbor.apps-tdh-1.vstkg.pcfsdu.com+1-key.pem

  if [ ! -f $HARBOR_TLS_CERT ]; then 
    mkcert harbor.apps-tdh-1.vstkg.pcfsdu.com notary.apps-tdh-1.vstkg.pcfsdu.com
  fi
else
  HARBOR_TLS_CERT=/Users/sdubois/icloud/Development/tanzu-demo-hub/certificates/vstkg.pcfsdu.com/fullchain.pem
  HARBOR_TLS_KEY=/Users/sdubois/icloud/Development/tanzu-demo-hub/certificates/vstkg.pcfsdu.com/privkey.pem
fi

helm uninstall harbor -n $HARBOR_NAMESPACE >/dev/null 2>&1
kubectl delete ns $HARBOR_NAMESPACE > /dev/null 2>&1
kubectl create ns $HARBOR_NAMESPACE > /dev/null 2>&1
kubectl -n $HARBOR_NAMESPACE create secret tls harbor-certs --cert=$HARBOR_TLS_CERT  --key=$HARBOR_TLS_KEY

echo "harborAdminPassword: $HARBOR_PASS"                                           >  $HARBOR_VALUES
echo ""                                                                            >> $HARBOR_VALUES
echo "service:"                                                                    >> $HARBOR_VALUES
echo "  type: LoadBalancer"                                                        >> $HARBOR_VALUES
echo "  tls:"                                                                      >> $HARBOR_VALUES
echo "    enabled: true"                                                           >> $HARBOR_VALUES
echo "    existingSecret: harbor-certs"                                            >> $HARBOR_VALUES
echo "    notaryExistingSecret: notary-certs"                                      >> $HARBOR_VALUES
echo ""                                                                            >> $HARBOR_VALUES
echo "ingress:"                                                                    >> $HARBOR_VALUES
echo "  enabled: true"                                                             >> $HARBOR_VALUES
echo "  hosts:"                                                                    >> $HARBOR_VALUES
echo "    core: $DNS_HARBOR"                                                       >> $HARBOR_VALUES
echo "    notary: $DNS_NOTARY"                                                     >> $HARBOR_VALUES
echo "  annotations:"                                                              >> $HARBOR_VALUES
echo "    ingress.kubernetes.io/force-ssl-redirect: \"true\""                      >> $HARBOR_VALUES
echo "    kubernetes.io/ingress.class: contour"                                    >> $HARBOR_VALUES
echo "externalURL: https://$DNS_HARBOR"                                            >> $HARBOR_VALUES
echo ""                                                                            >> $HARBOR_VALUES
echo "portal:"                                                                     >> $HARBOR_VALUES
echo "  tls:"                                                                      >> $HARBOR_VALUES
echo "    existingSecret: harbor-certs"                                            >> $HARBOR_VALUES

# --- DEFINE CONFIG FROm TEMPLATE ---
#helm show values bitnami/harbor > $HARBOR_VALUES
#gsed -i 's/^  secretName: .*$/  secretName: "harbor-certs"/g' $HARBOR_VALUES
#gsed -i 's/existingSecret:.*$/existingSecret: "harbor-certs"/g' $HARBOR_VALUES
#gsed -i 's/^harborAdminPassword:.*$/harborAdminPassword: Password12345/g' $HARBOR_VALUES

helm install harbor bitnami/harbor -f $HARBOR_VALUES -n $HARBOR_NAMESPACE --version 9.2.2

# --- TESTING REGISTRY ---
docker login $DNS_HARBOR -u admin -p $HARBOR_PASS > /dev/null 2>&1
if [ $? -ne 0 ]; then  
  echo "ERROR: Docker login does not work"
  echo "       => docker login $DNS_HARBOR -u admin -p $HARBOR_PASS"; exit
fi



