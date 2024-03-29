#!/bin/bash
# ############################################################################################
# File: ........: files/tdh-tools/tdh-context.sh
# Language .....: bash  
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Dockerfile for tdh-tools container
# ############################################################################################

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

  TIMEOUT=3s
  TKG_MC_LIST=""
  TKG_WC_LIST=""
  [ "$VERIFY" == "" ] && export VERIFY="false"
  [ ! -f $HOME/.kube/config ] && touch $HOME/.kube/config
export VERIFY="true"

  # --- VERIFY VPN"
  curl -k --head -m 3 https://h2o.vmware.com > /dev/null 2>&1; ret=$?
  [ $ret -ne 0 ] && VPN_ENABLED=1 || VPN_ENABLED=0

fi
  #########################################################################################################################
  ##################################### VERIFY MANAGEMENT / SUPERVISOR CLUSTER ############################################
  #########################################################################################################################
  for n in $(find $HOME/.tanzu-demo-hub/config -name "*.kubeconfig" 2>/dev/null | egrep "tkgmc|tcemc|/tdh"); do
    cnm=$(echo $n | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')
    vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere")
    mgt=$(echo $n | awk -F'/' '{ print $NF }' | egrep -c "tkgmc|tcemc")

    [ $vsp -gt 0 ] && TKG_MC_LIST="$TKG_MC_LIST $cnm" || TKG_WC_LIST="$TKG_WC_LIST $cnm"
    TKG_CLUSTER_IS_MGMT[$INDEX]="true"

    found=0
    for file in $(ls -1 $HOME/.tanzu-demo-hub/config/TDHenv-*.cfg); do
      cfg=$(echo $file | awk -F'/' '{ print $NF }')
      ccc=$(grep -c "TDH_TKGMC_NAME=${cnm}" $HOME/.tanzu-demo-hub/config/${cfg})
      [ $ccc -eq 1 ] && found=1 && break
    done

    if [ $found -eq 1 ]; then
      TKG_CLUSTER_CONFIG_FILE=$cfg
    else
      echo "ERROR: TKG Cluster $cnm could not be found in a \$HOME/.tanzu-demo-hub/config/TDHenv-*.cfg files"
      exit
    fi

    TKG_CLUSTER_NAME[$INDEX]="$cnm"
    TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API UNTESTED"
    TKG_CLUSTER_CONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${TKG_CLUSTER_CONFIG_FILE}

    TKG_CLUSTER_KUBECONFIG[$INDEX]=$HOME/.tanzu-demo-hub/config/${cnm}.kubeconfig
    TKG_CLUSTER_COMMENT[$INDEX]="$(egrep 'TDH_TKGMC_COMMENT' $HOME/.tanzu-demo-hub/config/${TKG_CLUSTER_CONFIG_FILE} | awk -F '=' '{ print $2 }' | sed 's/"//g')"

    [ ! -s ${TKG_CLUSTER_CONFIG[$INDEX]} ] && continue
    vsp=$(egrep -c "TDH_TKGMC_INFRASTRUCTURE=vSphere|TDH_TKGMC_VSPHERE_NAMESPACE=" ${TKG_CLUSTER_CONFIG[$INDEX]})
    [ "$vsp" -gt 0 ] && TKG_CLUSTER_IS_VSPHERE[$INDEX]="true" || TKG_CLUSTER_IS_VSPHERE[$INDEX]="false"
    
    [ -s ${TKG_CLUSTER_CONFIG[$INDEX]} ] && . ${TKG_CLUSTER_CONFIG[$INDEX]}   ## READ ENVIRONMENT VARIABLES FROM CONFIG FILE
    export KUBECONFIG=$HOME/.kube/config
    export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

    [ -s $HOME/.kube/config ] && mv $HOME/.kube/config $HOME/.kube/config.old

    export KUBECONFIG=$HOME/.kube/config
    export KUBECTL_VSPHERE_PASSWORD=$TDH_TKGMC_VSPHERE_PASS

    kubectl vsphere login --insecure-skip-tls-verify --server $TDH_TKGMC_SUPERVISORCLUSTER -u $TDH_TKGMC_VSPHERE_USER > /tmp/error.log 2>&1; ret=$?
    if [ $ret -eq 0 ]; then
      TKG_CLUSTER_STATUS[$INDEX]="ok"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API OK"
    else
      TKG_CLUSTER_STATUS[$INDEX]="nok"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API FAILED"
    fi

    [ -s $HOME/.kube/config ] && mv $HOME/.kube/config ${TKG_CLUSTER_KUBECONFIG[$INDEX]}
    [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config

    let INDEX=INDEX+1
  done

  CONTEXT_LIST=""
  # --- GATHER RIGHT KUBECONFIG ---
  for n in $(find $HOME/.tanzu-demo-hub/deployments -name "*.kubeconfig" 2>/dev/null | egrep "tkgmc|tcemc|/tdh"); do
    cnm=$(echo $n | awk -F'/' '{ print $NF }' | awk -F'.' '{ print $1 }')
    vsp=$(echo $n | egrep -c "tkgmc-vsphere|tcemc-vsphere") 
    mgt=$(echo $n | awk -F'/' '{ print $NF }' | egrep -c "tkgmc|tcemc") 
    [ "$vsp" -gt 0 ] && TKG_CLUSTER_IS_VSPHERE[$INDEX]="true" || TKG_CLUSTER_IS_VSPHERE[$INDEX]="false"

    dep=$(echo $n | awk -F '/' '{ print $(NF-2) }')
    mcn=$(echo $n | awk -F '/' '{ print $(NF-3) }')
    TKG_CLUSTER_NAME[$INDEX]="$cnm"
    TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API UNTESTED"
    TKG_CLUSTER_CONFIG[$INDEX]=$HOME/.tanzu-demo-hub/deployments/${mcn}/${dep}/${cnm}/${cnm}.cfg
    TKG_CLUSTER_KUBECONFIG[$INDEX]=$HOME/.tanzu-demo-hub/deployments/${mcn}/${dep}/${cnm}/${cnm}.kubeconfig
    TKG_CLUSTER_IS_MGMT[$INDEX]="false"

    if [ $vsp -eq 1 ]; then 
      IDX=0 
      while [ $IDX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
        [ "${TKG_CLUSTER_NAME[$IDX]}" == "$mcn" ] && mcs=${TKG_CLUSTER_STATUS[$IDX]}; let IDX=IDX+1
      done
    else
      mcs="ok"
    fi

    if [ "$mcs" == "ok" ]; then 
      # --- VERIFY CLUSTER ---
      if [ "$VERIFY" == "true" ]; then
        kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
        [ $ret -eq 0 ] && TKG_CLUSTER_STATUS[$INDEX]="ok"  && TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API OK"
        [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" && TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API FAILED"
      else
        TKG_CLUSTER_STATUS[$INDEX]="na"
        TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API UNTESTED"
      fi
  
      # --- IF THE CLUSTER STATUS IS 'NOK' AND THE CKUSTER IS OF TYPE VSPHERE, THEN LOGIN AND MAKE NEW KUBECONFIG ---
      if [ "${TKG_CLUSTER_STATUS[$INDEX]}" == "nok" -a "${TKG_CLUSTER_IS_VSPHERE[$INDEX]}" == "true" ]; then
        # --- SKIP TEST IF VPN IS NOT ENABLED ---
        if [ $VPN_ENABLED -eq 0 ]; then
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
              TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API FAILED"
            else
              TKG_CLUSTER_STATUS[$INDEX]="ok"
              TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API OK"
            fi
          fi
  
          [ -s $HOME/.kube/config.old ] && mv $HOME/.kube/config.old $HOME/.kube/config
  
          # --- VERIFY CLUSTER ACCESS AGAIN---
          if [ "$VERIFY" == "true" ]; then
            kubectl --kubeconfig=${TKG_CLUSTER_KUBECONFIG[$INDEX]} --request-timeout $TIMEOUT get ns >/dev/null 2>&1; ret=$?
            [ $ret -eq 0 ] && TKG_CLUSTER_STATUS[$INDEX]="ok"  && TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API OK"
            [ $ret -ne 0 ] && TKG_CLUSTER_STATUS[$INDEX]="nok" && TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API FAILED"
          else
            TKG_CLUSTER_STATUS[$INDEX]="na"
            TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API UNTESTED"
          fi
        else
          TKG_CLUSTER_STATUS_MSG[$INDEX]="VMWARE-VPN-DOWN"
          echo "ERROR: Can not verify $nam as connection to VMware VPN is required"
        fi
      fi
    else
      TKG_CLUSTER_STATUS[$INDEX]="nok"
      TKG_CLUSTER_STATUS_MSG[$INDEX]="K8S-API FAILED"
    fi
  
    let INDEX=INDEX+1
  done

  echo "" 
  echo " TANZU-DEMO-HUB MANAGEMENT / SUPERVISOR CLUSTERS"
  echo " -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- "
  INDEX=0 
  while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
    if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" == "true" ]; then 
      pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed 's+^.*/.tanzu-demo-hub+$HOME/.tanzu-demo-hub+g')
      des=$(echo ${TKG_CLUSTER_COMMENT[$INDEX]})
      printf " export KUBECONFIG=%-81s   ## %-87s %-20s\n" $pth "$des"  "## ${TKG_CLUSTER_STATUS_MSG[$INDEX]}"
    fi
          
    let INDEX=INDEX+1
  done

  for n in $(find $HOME/.tanzu-demo-hub/deployments -name config.yml); do
     tmc=$(echo $n | awk -F'/' '{ print $(NF-2) }') 
     dep=$(yq -o json $n | jq -r '.tdh_deployment.name')
     cfg=$(yq -o json $n | jq -r '.tdh_deployment.source' | sed 's/\.j2//g')
     des=$(yq -o json $n | jq -r '.tdh_deployment.description')
     sdm=$(yq -o json $n | jq -r '.tdh_environment.network.dns.dns_subdomain')
     tde=$(egrep "TDH_TKGMC_NAME=${tmc}" $HOME/.tanzu-demo-hub/config/TDHenv*.cfg | awk -F: '{ print $1 }' | awk -F'/' '{ print $NF }' | sed 's/\.cfg//g') 

     echo ""
     echo " Deployment.............: ${tmc}/${dep}"
     echo " Description............: ${des}"
     echo " Deployment Command ....: deployTDH -e $tde -c $cfg -sd $sdm"
     if [ -f "$HOME/.tanzu-demo-hub/deployments/${tmc}/${dep}/${dep}.log" ]; then 
       echo " Deployment Logfile ....: \$HOME/.tanzu-demo-hub/deployments/${tmc}/${dep}/${dep}.log"
     fi
     echo " -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- "

     INDEX=0 
     while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
       if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" != "true" ]; then 
         cnt=$(echo "${TKG_CLUSTER_KUBECONFIG[$INDEX]}" | grep -c ".tanzu-demo-hub/deployments/${tmc}/${dep}") 
         if [ $cnt -eq 1 ]; then 
           pth=$(echo ${TKG_CLUSTER_KUBECONFIG[$INDEX]} | sed 's+^.*/.tanzu-demo-hub+$HOME/.tanzu-demo-hub+g')
           printf " export KUBECONFIG=%-173s  %-20s\n" "$pth"  "## ${TKG_CLUSTER_STATUS_MSG[$INDEX]}"
         fi
       fi

       let INDEX=INDEX+1
     done

     echo ""
     echo " Consolidated KUBECONFIG:"
     echo "    export KUBECONFIG=\$HOME/.tanzu-demo-hub/deployments/${tmc}/${dep}/kubeconfig_${dep}.yaml"
     INDEX=0
     while [ $INDEX -lt ${#TKG_CLUSTER_NAME[@]} ]; do
       if [ "${TKG_CLUSTER_IS_MGMT[$INDEX]}" != "true" ]; then
         cnt=$(echo "${TKG_CLUSTER_KUBECONFIG[$INDEX]}" | grep -c ".tanzu-demo-hub/deployments/${tmc}/${dep}")
         if [ $cnt -eq 1 ]; then
           printf "    => %-100s ## %s\n" "kubectl config use-context ${TKG_CLUSTER_NAME[$INDEX]}-admin@${TKG_CLUSTER_NAME[$INDEX]}" "Workload Cluster: ${TKG_CLUSTER_NAME[$INDEX]}"
         fi
       fi

       let INDEX=INDEX+1
     done
     echo " -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- "
  done

unset KUBECTL_VSPHERE_PASSWORD
unset KUBECONFIG
unset SUPERVISOR
unset VERIFY

[ "$(hostname)" == "tdh-tools" ] && cd $HOME/tanzu-demo-hub && /bin/bash 



