#!/bin/bash
# ############################################################################################
# File: ........: files/tdh-tools/tdh-context.sh
# Language .....: bash  
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Dockerfile for tdh-tools container
# ############################################################################################

#########################################################################################################################
#Execute a command"#################################### VERIFY MANAGEMENT / SUPERVISOR CLUSTER ############################################
#########################################################################################################################
if [ -d $HOME/.tanzu-demo-hub/config ]; then 
  declare -a TKG_CLUSTER_KUBECONFIG
  declare -a TKG_CLUSTER_CONFIG
  declare -a TKG_CLUSTER_IS_VSPHERE
  declare -a TKG_CLUSTER_IS_MGMT
  declare -a TKG_CLUSTER_COMMENT
  declare -a TKG_CLUSTER_STATUS
  declare -a TKG_CLUSTER_STATUS_MSG
  declare -a TKG_CLUSTER
  declare -a TKG_CLUSTER_NAME
  declare -a TKG_CLUSTER_TYPE
  declare -a TKG_CLUSTER_TDHV2

  TIMEOUT=3s
  TKG_MC_LIST=""
  TKG_WC_LIST=""
  [ "$SUPERVISOR" == "" ] && export SUPERVISOR="false"
  [ "$VERIFY" == "" ] && export VERIFY="false"

  # --- VERIFY VPN"
  curl -k --head -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
  [ $ret -ne 0 ] && VPN_ENABLED=1 || VPN_ENABLED=0

  CONTEXT_LIST=""; INDEX=0
  # --- GATHER RIGHT KUBECONFIG ---
  for n in $(find $HOME/.tanzu-demo-hub -name "*.kubeconfig" 2>/dev/null | egrep "tkgmc|tcemc|/tdh"); do
    cnm=$(echo $n | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')
    vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
    dh2=$(echo $n | egrep -c "deployment") 
    mgt=$(echo $n | awk -F'/' '{ print $NF }' | egrep -c "tkgmc|tcemc") 
    [ $vsp -gt 0 ] && TKG_MC_LIST="$TKG_MC_LIST $cnm" || TKG_WC_LIST="$TKG_WC_LIST $cnm"
  
    [ "$dh2" -eq 1 ] && TKG_CLUSTER_TDHV2[$INDEX]="true" || TKG_CLUSTER_TDHV2[$INDEX]="false"
    if [ "${TKG_CLUSTER_TDHV2[$INDEX]}" == "true" ]; then
      dep=$(echo $n | awk -F '/' '{ print $(NF-2) }')
      mcn=$(echo $n | awk -F '/' '{ print $(NF-3) }')
      TKG_CLUSTER_NAME[$INDEX]="$cnm"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOT-TESTED"
      TKG_CLUSTER_CONFIG[$INDEX]=$HOME/.tanzu-demo-hub/deployments/${mcn}/${dep}/${cnm}/${cnm}.cfg
      TKG_CLUSTER_KUBECONFIG[$INDEX]=$HOME/.tanzu-demo-hub/deployments/${mcn}/${dep}/${cnm}/${cnm}.kubeconfig
    else
      TKG_CLUSTER_NAME[$INDEX]="$cnm"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOT-TESTED"
      TKG_CLUSTER_CONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${cnm}.cfg
      TKG_CLUSTER_KUBECONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${cnm}.kubeconfig
      TKG_CLUSTER_COMMENT[$INDEX]="$(egrep 'TDH_TKGMC_COMMENTS' $HOME/.tanzu-demo-hub/config/${cnm}.cfg | awk -F '=' '{ print $2 }' | sed 's/"//g')"
    fi

    vsp=$(egrep -c "TDH_TKGMC_INFRASTRUCTURE=vSphere|TDH_TKGMC_VSPHERE_NAMESPACE=" ${TKG_CLUSTER_CONFIG[$INDEX]})
    [ "$vsp" -gt 0 ] && TKG_CLUSTER_IS_VSPHERE[$INDEX]="true" || TKG_CLUSTER_IS_VSPHERE[$INDEX]="false"
    [ "$mgt" == "1" ] && TKG_CLUSTER_IS_MGMT[$INDEX]="true" || TKG_CLUSTER_IS_MGMT[$INDEX]="false"
  
    # --- ONLY DO MANAGEMENT CLUSTERS IF NEEDED ---
    [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" -a "$SUPERVSOR" == "false" ] && continue
  
    # --- VERIFY CLUSTER ---
    if [ "$VERIFY" == "true" ]; then
      kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
      [ $ret -eq 0 ] && TKG_CLUSTER_STATUS[$INDEX]="ok"  && TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-OK"
      [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" && TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOK"
    else
      TKG_CLUSTER_STATUS[$INDEX]="na"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOT-TESTED"
    fi
  
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
          if [ $ret -eq 0 ]; then
            TKG_CLUSTER_STATUS[$INDEX]="ok" 
            TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-OK"
          else
            TKG_CLUSTER_STATUS[$INDEX]="na"
            TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOT-TESTED"
          fi

          [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
          [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
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
  
          if [ $ret -eq 0 ]; then 
            kubectl get secrets ${cnm}-kubeconfig -o jsonpath='{.data.value}' 2>/dev/null | base64 -d > ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
            if [ ! -s ${TKG_CLUSTER_KUBECONFIG[$INDEX]} ]; then 
              TKG_CLUSTER_STATUS[$INDEX]="nok"
              TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOK"
            else
              TKG_CLUSTER_STATUS[$INDEX]="ok"
              TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-OK"
            fi
          fi
  
          [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  
          # --- VERIFY CLUSTER ACCESS AGAIN---
          if [ "$VERIFY" == "true" ]; then
            kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
            [ $ret -eq 0 ] && TKG_CLUSTER_STATUS[$INDEX]="ok"  && TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-OK"
            [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" && TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOK"
          else
            TKG_CLUSTER_STATUS[$INDEX]="na"
            TKG_CLUSTER_STATUS_MSG[$INDEX]="KUBERNETES-API-NOT-TESTED"
          fi
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
    echo " -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    INDEX=0 
    while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
      if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" ]; then 
        pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed 's+/home/tanzu+$HOME+g')
        des=$(echo ${TKG_CLUSTER_COMMENT[$INDEX]})
        printf " export KUBECONFIG=%-77s   ## %-78s %25s\n" $pth "$des"  "[${TKG_CLUSTER_STATUS_MSG[$INDEX]}]"
      fi
          
      let INDEX=INDEX+1
    done
  fi

  echo ""
  echo " TANZU-DEMO-HUB WORKLOAD CLUSTERS"
  echo " -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
  INDEX=0 
  while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
    if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" != "true" ]; then 
      pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed 's+/home/tanzu+$HOME+g')
      printf " export KUBECONFIG=%-165s  %20s\n" "$pth"  "[${TKG_CLUSTER_STATUS_MSG[$INDEX]}]"
    fi
  
    let INDEX=INDEX+1
  done
  echo  
fi 

/bin/bash
