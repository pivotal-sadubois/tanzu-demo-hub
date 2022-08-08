#!/bin/bash

kubectl -n metadata-store get httpproxy -o json | \
jq 'select(.items[].spec.virtualhost.tls.secretName == "ingress-cert") | .items[].spec.virtualhost.tls.secretName |= "tdh-cert-admin/tanzu-demo-hub-tls"' > /tmp/metadata-store.json

kubectl -n metadata-store apply -f /tmp/metadata-store.json



