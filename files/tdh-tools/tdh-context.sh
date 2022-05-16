#!/bin/bash

TIMEOUT=3s

# ------------------------------------------------------------------------------------------
# Function Name ......: verify_vpn
# Function Purpose ...: Verify VPN Access for PEZ/H2O Demo Environments
# ------------------------------------------------------------------------------------------
# Argument ($1) ......: Supervisor Cluster
# ------------------------------------------------------------------------------------------
# Return Value .......: 0=No VPN Required, 1=VPN Required but not connectec
# ------------------------------------------------------------------------------------------
verify_vpn() {
  vpn=0
  CLUSTER=$1
  
  cnt=$(echo $CLUSTER | egrep -c "pez.vmware.com") 
  if [ $cnt -gt 0 ]; then  
    curl -m 3 https://pez-portal.int-apps.pcfone.io > /dev/null 2>&1; ret=$?
    [ $ret -ne 0 ] && vpn=1
  fi

  cnt=$(echo $CLUSTER | egrep -c "h2o.vmware.com")
  if [ $cnt -gt 0 ]; then
    curl -k -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
    [ $ret -ne 0 ] && vpn=1
  fi

  echo $vpn
}

#########################################################################################################################
##################################### VERIFY MANAGEMENT / SUPERVISOR CLUSTER ############################################
#########################################################################################################################
CONTEXT_LIST=""; CONTEXT_BAD=""
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/*.kubeconfig 2>/dev/null | egrep "tkgmc|tcemc"); do
  nam=$(echo $n | sed 's/kubeconfig/cfg/g')
  vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
  [ -s $nam ] && . ${nam}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE

  if [ $vsp -gt 0 ]; then 
    # --- SKIP TEST IF VPN IS NOT ENABLED ---
    vpn=$(verify_vpn $TDH_TKGMC_SUPERVISORCLUSTER) 
    if [ $vpn -eq 0 ]; then
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old
  
      export KUBECONFIG=$HOME/.kube/config
      export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS
      kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?
  
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $n
      [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  
      kubectl --kubeconfig=$n --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
      if [ $ret -eq 0 ]; then
        nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
        CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
      else
	CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
      fi
    else
      echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
    fi
  else
    # --- REGULAR CLUSTER (NOT-VSPHERE) ----
    kubectl --kubeconfig=$n --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
    if [ $ret -eq 0 ]; then
      nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
      CONTEXT_LIST="$CONTEXT_LIST $nam:$n"
    else
      CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
    fi
  fi
done

#########################################################################################################################
############################################### VERIFY TKG CLUSTERS #####################################################
#########################################################################################################################
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/tdh*.kubeconfig 2>/dev/null); do
  nam=$(echo $n | awk -F'/' '{ print $NF }' | sed 's/\.kubeconfig//g')
  vsp=$(grep -c "TDH_TKGMC_NAME=tkgmc-vsphere" $HOME/.tanzu-demo-hub/config/${nam}.cfg 2>/dev/null) 
  [ "$vsp" == "" ] && vsp=0

  if [ $vsp -gt 0 ]; then
    [ -s $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
    [ -s $HOME/.tanzu-demo-hub/config/${nam}.cfg ] && . $HOME/.tanzu-demo-hub/config/${nam}.cfg

    # --- SKIP TEST IF VPN IS NOT ENABLED ---
    vpn=$(verify_vpn $TDH_TKGMC_SUPERVISORCLUSTER)
    if [ $vpn -eq 0 ]; then
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

      # --- LOGIN TO THE SUPERVISOR CLUSTER FIRST ---
      export KUBECONFIG=$HOME/.kube/config
      export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_TKGS_VCENTER_PASSWORD

      kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER \
          -u $VSPHERE_TKGS_VCENTER_ADMIN --tanzu-kubernetes-cluster-name $nam \
          --tanzu-kubernetes-cluster-namespace $TDH_TKGMC_VSPHERE_NAMESPACE > /dev/null 2>&1; ret=$?

      [ $ret -ne 0 ] && CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
      [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $n
      [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
    else
      echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
    fi
  fi

  kubectl --kubeconfig=$n --request-timeout $TIMEOUT get cm -n default -o json > /tmp/output.json 2>/dev/null; ret=$?
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

