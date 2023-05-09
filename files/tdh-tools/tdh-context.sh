#!/bin/bash
# ############################################################################################
# File: ........: files/tdh-tools/tdh-context.sh
# Language .....: bash  
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Dockerfile for tdh-tools container
# ############################################################################################

declare -a TKG_CLUSTER_KUBECONFIG
declare -a TKG_CLUSTER_CONFIG
declare -a TKG_CLUSTER_IS_VSPHERE
declare -a TKG_CLUSTER_IS_MGMT
declare -a TKG_CLUSTER_STATUS
declare -a TKG_CLUSTER_STATUS_MSG
declare -a TKG_CLUSTER
declare -a TKG_CLUSTER_NAME
declare -a TKG_CLUSTER_TYPE

TIMEOUT=3s
TKG_MC_LIST=""
TKG_WC_LIST=""
[ "$SUPERVISOR" == "" ] && export SUPERVISOR="false"

# --- VERIFY VPN"
curl -k --head -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
[ $ret -ne 0 ] && VPN_ENABLED=1 || VPN_ENABLED=0

#########################################################################################################################
##################################### VERIFY MANAGEMENT / SUPERVISOR CLUSTER ############################################
#########################################################################################################################
CONTEXT_LIST=""; INDEX=0
# --- GATHER RIGHT KUBECONFIG ---
for n in $(ls -1 $HOME/.tanzu-demo-hub/config/*.kubeconfig 2>/dev/null | egrep "tkgmc|tcemc|/tdh"); do
  cnm=$(echo $n | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')
  vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
  mgt=$(echo $n | egrep -c "tkgmc|tcemc") 
  [ $vsp -gt 0 ] && TKG_MC_LIST="$TKG_MC_LIST $cnm" || TKG_WC_LIST="$TKG_WC_LIST $cnm"

  TKG_CLUSTER_NAME[$INDEX]="$cnm"
  TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-OK"
  TKG_CLUSTER_CONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${cnm}.cfg
  TKG_CLUSTER_KUBECONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${cnm}.kubeconfig
  vsp=$(egrep -c "TDH_TKGMC_INFRASTRUCTURE=vSphere|TDH_TKGMC_VSPHERE_NAMESPACE=" ${TKG_CLUSTER_CONFIG[$INDEX]})
  [ "$vsp" -gt 0 ] && TKG_CLUSTER_IS_VSPHERE[$INDEX]="true" || TKG_CLUSTER_IS_VSPHERE[$INDEX]="false"
  [ "$mgt" == "1" ] && TKG_CLUSTER_IS_MGMT[$INDEX]="true" || TKG_CLUSTER_IS_MGMT[$INDEX]="false"

  # --- ONLY DO MANAGEMENT CLUSTERS IF NEEDED ---
  [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" -a "$SUPERVISOR" == "false" ] && continue

  # --- VERIFY CLUSTER ---
  kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
  [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" || TKG_CLUSTER_STATUS[$INDEX]="ok"

  # --- IF THE CLUSTER STATUS IS 'NOK' AND THE CKUSTER IS OF TYPE VSPHERE, THEN LOGIN AND MAKE NEW KUBECONFIG ---
  if [ "${TKG_CLUSTER_STATUS[$INDEX]}" == "nok" -a "${TKG_CLUSTER_IS_VSPHERE[$INDEX]}" == "true" ]; then
    # --- SKIP TEST IF VPN IS NOT ENABLED ---
    if [ $VPN_ENABLED -eq 0 ]; then
      if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" ]; then
        [ -s ${TKG_CLUSTER_CONFIG[$INDEX]} ] && . ${TKG_CLUSTER_CONFIG[$INDEX]}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE
        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
        [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config

        # --- VERIFY CLUSTER ACCESS AGAIN---
        kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
        [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" || TKG_CLUSTER_STATUS[$INDEX]="ok"
      else
        [ -s ${TKG_CLUSTER_CONFIG[$INDEX]} ] && . ${TKG_CLUSTER_CONFIG[$INDEX]}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE
        [ -s $HOME/.tanzu-demo-hub/config/${TDH_TKGMC_NAME}.cfg ] && . $HOME/.tanzu-demo-hub/config/${TDH_TKGMC_NAME}.cfg

        # --- LOGIN TO THE SUPERVISOR CLUSTER FIRST ---
        export KUBECONFIG=$HOME/.kube/config
        export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_TKGS_VCENTER_PASSWORD
        export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

        kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER \
           -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?

        if [ $ret -ne 0 ]; then 
          kubectl get secrets ${cnm}-kubeconfig -o jsonpath='{.data.value}' | base64 -d > ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
          TKG_CLUSTER_STATUS[$INDEX]="ok"
        fi

        [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
        [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config

        # --- VERIFY CLUSTER ACCESS AGAIN---
        kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
        [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" || TKG_CLUSTER_STATUS[$INDEX]="ok"
        [ "${TKG_CLUSTER_STATUS[$INDEX]}" == "nok" ] && TKG_CLUSTER_STATUS_MSG[$INDEX]="VSPHERE-LOGIN-FAILED"
      fi
    else
      TKG_CLUSTER_STATUS_MSG[$INDEX]="VMWARE-VPN-NOT-ACTIVE"
      echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
    fi
  fi

  [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" ] && CL_MC_LIST="$CL_MC_LIST $cnm" || CL_WC_LIST="$CL_WC_LIST $cnm"
  let INDEX=INDEX+1
done

if [ "$SUPERVISOR" == "true" ]; then 
  echo "" 
  echo " TANZU-DEMO-HUB MANAGEMENT CLUSTERS"
  echo " ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  INDEX=0 
  while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
    if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" ]; then 
      pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed "s+/home/tanzu+$HOME+g")
      printf " export KUBECONFIG=%-82s   ## %-40s %25s\n" $pth $cnm  "[${TKG_CLUSTER_STATUS_MSG[$INDEX]}]"
    fi
          
    let INDEX=INDEX+1
  done
fi

echo ""
echo " TANZU-DEMO-HUB WORKLOAD CLUSTERS"
echo " ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
INDEX=0 
while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
  if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" != "true" ]; then 
    pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed "s+/home/tanzu+$HOME+g")
    printf " export KUBECONFIG=%-82s   ## %-40s %25s\n" $pth $cnm  "[${TKG_CLUSTER_STATUS_MSG[$INDEX]}]"
  fi

  let INDEX=INDEX+1
done

echo  
#/bin/bash
