#!/bin/bash

CONTEXT_LIST=""
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/*.kubeconfig 2>/dev/null | egrep "tkgmc|tcemc"); do
  nam=$(echo $n | sed 's/kubeconfig/cfg/g')
  vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
  [ -s $nam ] && . ${nam}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE

  if [ $vsp -gt 0 ]; then 
    cnt=$(echo $TDH_TKGMC_SUPERVISORCLUSTER | egrep -c "pez.vmware.com") 
    if [ $cnt -gt 0 ]; then 
      curl -m 3 https://pez-portal.int-apps.pcfone.io > /dev/null 2>&1; ret=$?
      if [ $ret -eq 0 ]; then
        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old
  
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
        kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?
  
        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $n
        [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  
        kubectl --kubeconfig=$n --request-timeout 3s get ns >/dev/null 2>&1; ret=$?
        if [ $ret -eq 0 ]; then
          nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
          CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
        fi
      else
        echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
      fi
    else
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old
  
      export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
      kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?
  
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $n
      [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  
      kubectl --kubeconfig=$n --request-timeout 3s get ns >/dev/null 2>&1; ret=$?
      if [ $ret -eq 0 ]; then
        nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
        CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
      fi
    fi
  else
    # --- REGULAR CLUSTER (NOT-VSPHERE) ----
    kubectl --kubeconfig=$n --request-timeout 1s get ns >/dev/null 2>&1; ret=$?
    if [ $ret -eq 0 ]; then
      nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
      CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
      break
    fi
  fi
done

for n in $(ls -1 $HOME/.tanzu-demo-hub/config/tdh*.kubeconfig 2>/dev/null); do
  nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')

  kubectl --kubeconfig=$n --request-timeout 3s get cm -n default -o json > /tmp/output.json 2>/dev/null; ret=$?
  if [ $ret -eq 0 ]; then
    if [ -s /tmp/output.json ]; then
      cfm=$(jq -r '.items[].metadata | select(.name == "tanzu-demo-hub").name' /tmp/output.json 2>/dev/null)
      if [ "$cfm" == "tanzu-demo-hub" ]; then
        CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
      fi
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

