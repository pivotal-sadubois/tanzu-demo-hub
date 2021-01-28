

HARBOR_TLS_CERT=Harbor.apps-tdh-1.vstkg.pcfsdu.com+1.pem
HARBOR_TLS_KEY=harbor.apps-tdh-1.vstkg.pcfsdu.com+1-key.pem

if [ ! -f $HARBOR_TLS_CERT ]; then 
  mkcert harbor.apps-tdh-1.vstkg.pcfsdu.com notary.apps-tdh-1.vstkg.pcfsdu.com
fi

kubectl delete ns harbor > /dev/null 2>&1
kubectl create ns harbor > /dev/null 2>&1
kubectl create secret tls harbor-certs -n harbor \
  --cert=$HARBOR_TLS_CERT \
  --key=$HARBOR_TLS_KEY

helm show values bitnami/harbor > harbor-values.yaml
gsed -i 's/^  secretName: .*$/  secretName: "harbor-certs"/g' harbor-values.yaml
gsed -i 's/existingSecret:.*$/existingSecret: "harbor-certs"/g' harbor-values.yaml

helm install harbor bitnami/harbor -f harbor-values.yaml -n harbor --version 9.2.2

echo "kubectl get secret harbor-certs -n harbor  -o json | jq -r '.data.\"tls.crt\"' |  base64 --decode | openssl x509 -text -noout"
echo "curl -k https://192.168.64.100/api/v2.0/systeminfo/getcert 2>/dev/null | openssl x509 -text -noout 2>/dev/null"
