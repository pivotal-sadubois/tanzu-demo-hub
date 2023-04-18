#!/bin/bash

declare -A TKG_CLUSTER_KUBECONFIG
declare -A TKG_CLUSTER_CONFIG
declare -A TKG_CLUSTER_IS_VSPHERE
declare -A TKG_CLUSTER_IS_MGMT
declare -A TKG_CLUSTER_STATUS
declare -A TKG_CLUSTER_STATUS_MSG
declare -A TKG_CLUSTER
declare -A TKG_CLUSTER_TYPE

TIMEOUT=3s
TKG_MC_LIST=""
TKG_WC_LIST=""

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
  curl -k --head -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
  [ $ret -ne 0 ] && vpn=1

  echo $vpn
}

# ------------------------------------------------------------------------------------------
# Function Name ......: verify_kubernetes
# Function Purpose ...: Verify Access to the Kubernetes cluster
# ------------------------------------------------------------------------------------------
# Argument ($1) ......: Supervisor Cluster
# ------------------------------------------------------------------------------------------
# Return Value .......: ok=Login Succeeded, nok=Login not working
# ------------------------------------------------------------------------------------------
verify_kubernetes() {
  cfg=$1
  stt=ok
  kubectl --kubeconfig=$cfg --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?

  [ $ret -ne 0 ] && stt=nok

  echo $stt
}


# --- SKIP TEST IF VPN IS NOT ENABLED ---
VPN_ENABLED=$(verify_vpn)

#########################################################################################################################
##################################### VERIFY MANAGEMENT / SUPERVISOR CLUSTER ############################################
#########################################################################################################################
CONTEXT_LIST=""; CONTEXT_BAD=""
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/*.kubeconfig 2>/dev/null | egrep "tkgmc|tcemc|/tdh"); do
  cnm=$(echo $n | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')
  vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
  mgt=$(echo $n | egrep -c "tkgmc|tcemc") 
  [ $vsp -gt 0 ] && TKG_MC_LIST="$TKG_MC_LIST $cnm" || TKG_WC_LIST="$TKG_WC_LIST $cnm"

  TKG_CLUSTER_STATUS_MSG["$cnm"]="KUBERNETES-API-OK"
  TKG_CLUSTER_CONFIG[$cnm]=$HOME/.tanzu-demo-hub/config/${cnm}.cfg
  TKG_CLUSTER_KUBECONFIG[$cnm]=$HOME/.tanzu-demo-hub/config/${cnm}.kubeconfig
  vsp=$(egrep -c "TDH_TKGMC_INFRASTRUCTURE=vSphere|TDH_TKGMC_VSPHERE_NAMESPACE=" ${TKG_CLUSTER_CONFIG[$cnm]})
  [ $vsp -gt 0 ] && TKG_CLUSTER_IS_VSPHERE[$cnm]="true" || TKG_CLUSTER_IS_VSPHERE[$cnm]="false"
  [ "$mgt" == "1" ] && TKG_CLUSTER_IS_MGMT[$cnm]="true" || TKG_CLUSTER_IS_MGMT[$cnm]="false"

  # --- VERIFY CLUSTER ACCESS ---
  TKG_CLUSTER_STATUS["$cnm"]=$(verify_kubernetes ${TKG_CLUSTER_KUBECONFIG[$cnm]})

  # --- IF THE CLUSTER STATUS IS 'NOK' AND THE CKUSTER IS OF TYPE VSPHERE, THEN LOGIN AND MAKE NEW KUBECONFIG ---
  if [ "${TKG_CLUSTER_STATUS[$cnm]}" == "nok" -a "${TKG_CLUSTER_IS_VSPHERE[$cnm]}" == "true" ]; then
    # --- SKIP TEST IF VPN IS NOT ENABLED ---
    if [ $VPN_ENABLED -eq 0 ]; then
      if [ "${TKG_CLUSTER_IS_MGMT[$cnm]}" == "true" ]; then
        [ -s ${TKG_CLUSTER_CONFIG[$cnm]} ] && . ${TKG_CLUSTER_CONFIG[$cnm]}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE
        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$cnm]}
        [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config

        # --- VERIFY CLUSTER ACCESS AGAIN---
        TKG_CLUSTER_STATUS["$cnm"]=$(verify_kubernetes ${TKG_CLUSTER_KUBECONFIG[$cnm]})
      else
        [ -s ${TKG_CLUSTER_CONFIG[$cnm]} ] && . ${TKG_CLUSTER_CONFIG[$cnm]}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE
        [ -s $HOME/.tanzu-demo-hub/config/${TDH_TKGMC_NAME}.cfg ] && . $HOME/.tanzu-demo-hub/config/${TDH_TKGMC_NAME}.cfg

        # --- LOGIN TO THE SUPERVISOR CLUSTER FIRST ---
        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_TKGS_VCENTER_PASSWORD
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

        kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER \
            -u $TDH_TKGMC_VSPHERE_USER --tanzu-kubernetes-cluster-name $cnm \
            --tanzu-kubernetes-cluster-namespace $TDH_TKGMC_VSPHERE_NAMESPACE > /dev/null 2>&1; ret=$?

        [ $ret -ne 0 ] && CONTEXT_BAD="$CONTEXT_BAD $nam:$n"
        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$cnm]}
        [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config

        # --- VERIFY CLUSTER ACCESS AGAIN---
        TKG_CLUSTER_STATUS["$cnm"]=$(verify_kubernetes ${TKG_CLUSTER_KUBECONFIG[$cnm]})
        [ "${TKG_CLUSTER_STATUS[$cnm]}" == "nok" ] && TKG_CLUSTER_STATUS_MSG["$cnm"]="VSPHERE-LOGIN-FAILED"
      fi
    else
      TKG_CLUSTER_STATUS_MSG["$cnm"]="VMWARE-VPN-NOT-ACTIVE"
      echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
    fi
  fi

  [ "${TKG_CLUSTER_IS_MGMT[$cnm]}" == "true" ] && CL_MC_LIST="$CL_MC_LIST $cnm" || CL_WC_LIST="$CL_WC_LIST $cnm"
done

echo ""
echo " TANZU-DEMO-HUB ENVIRONMENT"
echo " ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
for cnm in $CL_MC_LIST $CL_WC_LIST; do
  pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$cnm]} | sed 's+/home/tanzu+$HOME+g')

  printf " export KUBECONFIG=%-82s   ## %-40s %25s\n" $pth $cnm  "[${TKG_CLUSTER_STATUS_MSG[$cnm]}]"
done

# --- SET LAST PATH AS ACTIVE PATH ---
export KUBECONFIG=$pth

echo 
/bin/bash

