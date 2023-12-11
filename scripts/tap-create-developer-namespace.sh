#!/bin/bash
# ############################################################################################
# File: ........: tap-create-developer-namespace.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Cathegory ....: TAP
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

export TDHHOME=$HOME/tanzu-demo-hub
export NAMESPACE=$1

if  [ "$NAMESPACE" == "" ]; then 
  echo "Usage: $0 <namespace>"; exit 1
fi

[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# --- VERIFY CLUSTER ACCESS ---
kubectl get ns > /tmp/error.log 2>&1; ret=$?
if [ $ret -ne 0 ]; then
  logMessages /tmp/error.log
  echo "ERROR: Kubernetes cluster not accessabel, please restart tdh-tools container to reinitiate cluster login"
  echo "       => tools/${TDH_TOOLS}.sh"
  exit
fi

# --- CREATE NAMESPACE If IT DOES NOT EXIST ----
[ "$NAMESPACE" != "default" ] && kubectl create ns --dry-run=client -o yaml $NAMESPACE | kubectl apply -f -

# --- CREATE TAP LABEL ---
echo  " ▪ Create a Namespace label for TAP: apps.tanzu.vmware.com/tap-ns=\"\""
echo  " ▪ Create a Namespace label for OPA/Gatekeeper Admission Policy: pod-security.kubernetes.io/enforce=baseline"
kubectl label namespaces $NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
kubectl label namespaces $NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1

# --- GENERATE TLS SECRET ---
TLS_SECRET=tdh-tls-secret
TDH_TLS_CERTIFICATE=/tmp/cert.pem
TDH_TLS_KEY=/tmp/key.pem

# https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.7/tap/cloud-native-runtimes-how-to-guides-knative-default-tls.html
nam=$(kubectl get secrets -n $NAMESPACE -o json | jq --arg key $TLS_SECRET -r '.items[].metadata | select(.name == $key).name')
if [ "$nam" != "$TLS_SECRET" ]; then 
  echo  " ▪ Create TLS Cert ($TLS_SECRET)"
  kubectl get secret $TLS_SECRET -n default -o json | jq -r '.data."tls.crt"' | base64 -d > $TDH_TLS_CERTIFICATE
  kubectl get secret $TLS_SECRET -n default -o json | jq -r '.data."tls.key"' | base64 -d > $TDH_TLS_KEY

  kubectl create -n $NAMESPACE secret tls $TLS_SECRET --key $TDH_TLS_KEY --cert $TDH_TLS_CERTIFICATE > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    echo "ERROR: failed to generate TLS certificate $TLS_SECRET in namespace $NAMESPACE"
    echo "       => kubectl create -n $NAMESPACE secret tls $TLS_SECRET --key $TDH_TLS_KEY --cert $TDH_TLS_CERTIFICATE"
    exit 1
  fi

  kubectl -n $NAMESPACE get TLSCertificateDelegation -o json > /tmp/output.json 2>/dev/null
  nam=$(jq -r --arg key "$tls_scrt" '.items[].metadata | select(.name == $key).name' /tmp/output.json)
  if [ "$nam" == "" ]; then
    echo  " ▪ Create TLS Cert Delegation"
    
    TMP_CONFIG=/tmp/tap_config.yaml
    echo ""                                                                                                                       >  $TMP_CONFIG
    echo "apiVersion: projectcontour.io/v1"                                                                                       >> $TMP_CONFIG
    echo "kind: TLSCertificateDelegation"                                                                                         >> $TMP_CONFIG
    echo "metadata:"                                                                                                              >> $TMP_CONFIG
    echo "  name: default-delegation"                                                                                             >> $TMP_CONFIG
    echo "  namespace: $NAMESPACE"                                                                                                >> $TMP_CONFIG
    echo "spec:"                                                                                                                  >> $TMP_CONFIG
    echo "  delegations:"                                                                                                         >> $TMP_CONFIG
    echo "    - secretName: $TLS_SECRET"                                                                                          >> $TMP_CONFIG
    echo "      targetNamespaces:"                                                                                                >> $TMP_CONFIG
    echo "      - $NAMESPACE"                                                                                                     >> $TMP_CONFIG

    kubectl apply -f $TMP_CONFIG > /dev/null 2>&1
  else
    messagePrint " ▪ Verify TLS Cert Delegation to all namespaces" "$CERTNAME"
  fi
fi



