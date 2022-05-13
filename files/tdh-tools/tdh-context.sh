#!/bin/bash

CONTEXT_LIST=""; CONTEXT_BAD=""
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/*.kubeconfig 2>/dev/null | egrep "tkgmc|tcemc"); do
  nam=$(echo $n | sed 's/kubeconfig/cfg/g')
  vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
  [ -s $nam ] && . ${nam}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE

  if [ $vsp -gt 0 ]; then 
    cnt=$(echo $TDH_TKGMC_SUPERVISORCLUSTER | egrep -c "pez.vmware.com|h2o.vmware.com") 
    if [ $cnt -gt 0 ]; then 
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
      fi

      cnt=$(echo $TDH_TKGMC_SUPERVISORCLUSTER | egrep -c "h2o.vmware.com")               
      if [ $cnt -gt 0 ]; then
        curl -k -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
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
      else
        CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
      fi
    fi
  else
    # --- REGULAR CLUSTER (NOT-VSPHERE) ----
    kubectl --kubeconfig=$n --request-timeout 1s get ns >/dev/null 2>&1; ret=$?
    if [ $ret -eq 0 ]; then
      nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
      CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
    else
      CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
    fi
  fi
done

for n in $(ls -1 $HOME/.tanzu-demo-hub/config/tdh*.kubeconfig 2>/dev/null); do
  nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
  cnt=$(grep -c "TDH_TKGMC_NAME=tkgmc-vsphere" $HOME/.tanzu-demo-hub/config/${nam}.cfg) 
  if [ $cnt -gt 0 ]; then
    . $HOME/.tanzu-demo-hub.cfg
    . $HOME/.tanzu-demo-hub/config/${nam}.cfg

    [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old
    export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
    export KUBECONFIG=$HOME/.kube/config
    kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER \
          -u $VSPHERE_TKGS_VCENTER_ADMIN --tanzu-kubernetes-cluster-name $nam \
          --tanzu-kubernetes-cluster-namespace $TDH_TKGMC_VSPHERE_NAMESPACE > /dev/null 2>&1; ret=$?
    [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $n
    [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  fi

  kubectl --kubeconfig=$n --request-timeout 3s get cm -n default -o json > /tmp/output.json 2>/dev/null; ret=$?
  if [ $ret -eq 0 ]; then
    if [ -s /tmp/output.json ]; then
      cfm=$(jq -r '.items[].metadata | select(.name == "tanzu-demo-hub").name' /tmp/output.json 2>/dev/null)
      if [ "$cfm" == "tanzu-demo-hub" ]; then
        CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
      else
        CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
      fi
    fi
  fi
done

echo ""
echo " TANZU-DEMO-HUB ENVIRONMENT"
echo " ---------------------------------------------------------------------------------------------------------------------------------------------------"
for n in $CONTEXT_BAD; do
  nam=$(echo $n | awk -F: '{ print $1 }')
  pth=$(echo $n | awk -F: '{ print $2 }')

  printf " export KUBECONFIG=%-80s   ## *UNREACHABLE* %s\n" $pth $nam
  export KUBECONFIG=$pth
done

for n in $CONTEXT_LIST; do
  nam=$(echo $n | awk -F: '{ print $1 }')
  pth=$(echo $n | awk -F: '{ print $2 }')

  printf " export KUBECONFIG=%-82s   ## %s\n" $pth $nam
  export KUBECONFIG=$pth
done

echo 
/bin/bash

