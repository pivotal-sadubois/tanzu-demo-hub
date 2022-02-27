#!/bin/bash

CONTEXT_LIST=""
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/tkgmc-vsphere*.kubeconfig); do
  nam=$(echo $n | sed 's/kubeconfig/cfg/g')
  . ${nam}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE

  [ -s $nam ] && . $nam
  [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

  export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
  kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?

  mv $HOME/.kube/config $n
  mv $HOME/.kube/config.old $HOME/.kube/config

  kubectl --kubeconfig=$n get ns >/dev/null 2>&1; ret=$?
  if [ $ret -eq 0 ]; then
    nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
    CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
  fi
done

for n in $(ls -1 $HOME/.tanzu-demo-hub/config/tdh*.kubeconfig); do
  nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')

  kubectl --kubeconfig=$n get cm -n default -o json > /tmp/output.json 2>/dev/null
  if [ -s /tmp/output.json ]; then
    cfm=$(jq -r '.items[].metadata | select(.name == "tanzu-demo-hub").name' /tmp/output.json 2>/dev/null)
    if [ "$cfm" == "tanzu-demo-hub" ]; then
      CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
    fi
  fi
done

echo ""
echo " TANZU-DEMO-HUB ENVIRONMENT"
echo " ---------------------------------------------------------------------------------------------------------------------------------------------------"
for n in $CONTEXT_LIST; do
  nam=$(echo $n | awk -F: '{ print $1 }')
  pth=$(echo $n | awk -F: '{ print $2 }')

  printf " export KUBECONFIG=%-80s   ## %s\n" $pth $nam
  export KUBECONFIG=$pth
done

echo 
/bin/bash

