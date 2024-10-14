#!/bin/bash

# ################################################################################################################
# File: ........: demo-guide.sh
# Language .....: bash 
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Newsletter Demo Guide
# ################################################################################################################
# Reference: 
# 1.) Generate an application with Application Accelerator
#     https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.7/tap/getting-started-generate-first-app.html
# 1.) Deploy an app on Tanzu Application Platform
#     https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.7/tap/getting-started-deploy-first-app.html
# ################################################################################################################
# https://github.com/sdubois-tapdemo/java-webapp/blob/main/catalog/catalog-info.yaml

TAP_DEVELOPER_NAMESPACE=java-webapp
TAP_WORKLOAD_NAME=java-webapp
TAP_WORKLOAD_FILE=${TAP_WORKLOAD_NAME}-gitops.yaml
TDH_DEMO_GIT_REPO=java-webapp
TDH_CARTO_GIT_REPO=${TDH_DEMO_GIT_REPO}-config
TDH_STAGE_PROD=prod
TDH_STAGE_TEST=test

#tanzu accelerator list --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator get tanzu-java-web-app --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator generate  tanzu-java-web-app --options '{"projecName":"tjwa"}' --server-url https://accelerator.dev.tapmc.v2steve.net

if [ "$1" == "" ]; then 
  echo "tdh init                               ## Initialize Newsletter Demo (Fork Git Repo)"
  echo "tdh setup                              ## Demo Setup"
  echo "tdh guide                              ## Show the Demo Guide"
  echo "tdh context,c [dev,ops,run,svc]        ## Set Kubernetes Context (dev,ops,svc,run)"
  echo "tdh supply-chain [gitops,devops]       ## OPS Supply Chain (gitops, regops)"
  echo "tdh clean"
fi

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $TDHHOME/functions ] && . $TDHHOME/functions

# https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow
if [ "$1" == "setup" ]; then 
  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  if [ "$2" == "" ]; then
    echo "tdh setup dev                        ## Deploy 'Newsletter Subspription' and 'Newsleter UI' from the git 'release/1.0.0' branch"
    echo "                                     ## - Clone git Repsitory $TDH_DEMO_GIT_REPO into \$HOME/workspace"
    echo "                                     ## - cwBuild 'Newsletter Subspription' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "                                     ## - cwBuild 'Newsletter UI' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "tdh setup regops                     ## Deploy 'Newsletter Subspription' and 'Newsleter UI' from the git 'release/1.0.0' branch"
    echo "                                     ## - cwBuild 'Newsletter Subspription' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "                                     ## - cwBuild 'Newsletter UI' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "tdh setup gitops                     ## Deploy 'Newsletter Subspription' and 'Newsleter UI' from the git 'release/1.0.0' branch"
    echo "                                     ## - cwBuild 'Newsletter Subspription' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "                                     ## - cwBuild 'Newsletter UI' with supply chain 'basic-image-to-url-package' on the ops cluster"
    echo "tdh setup delete                     ## Cleanup deployments and remove the local git repository \$HOME/workspace/$TDH_DEMO_GIT_REPO"
  fi

  if [ "$2" == "clean" ]; then
    echo "ERROR: Option '$2' not found, did you mean 'delete' instead ?"
    echo ""
  fi

  if [ "$2" == "delete" ]; then
    ########################################################################################################################
    ################################################## RUN CLUSTER #########################################################
    ########################################################################################################################
    echo " ✓ Deleting Workload on $TAP_CLUSTER_RUN"
    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null

    # --- STAGE TEST ---
    kubectl -n $TDH_STAGE_TEST delete -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml > /dev/null 2>&1 && sleep 60
    #emptyTAPNamespace $TAP_CONTEXT_RUN ${TDH_STAGE_TEST}
    createTAPNamespace $TAP_CONTEXT_RUN ${TDH_STAGE_TEST} recreate > /dev/null 2>&1

    # --- STAGE PROD ---
    kubectl -n $TDH_STAGE_PROD delete -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml > /dev/null 2>&1 && sleep 60
    #emptyTAPNamespace $TAP_CONTEXT_RUN ${TDH_STAGE_PROD}
    createTAPNamespace $TAP_CONTEXT_RUN ${TDH_STAGE_PROD} recreate > /dev/null 2>&1

    #deleteNamespace ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
    #createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1

    ########################################################################################################################
    ################################################## OPS CLUSTER #########################################################
    ########################################################################################################################
    echo " ✓ Deleting Workload on $TAP_CLUSTER_OPS"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null

    cnt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get workload 2>/dev/null | grep -c "$TAP_WORKLOAD_NAME") 
    [ $cnt -gt 0 ] && kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete workload $TAP_WORKLOAD_NAME > /dev/null 2>&1 && sleep 60
    createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-regops recreate > /dev/null 2>&1

    cnt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops get workload 2>/dev/null | grep -c "$TAP_WORKLOAD_NAME") 
    [ $cnt -gt 0 ] && kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete workload $TAP_WORKLOAD_NAME > /dev/null 2>&1 && sleep 60
    createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-gitops recreate > /dev/null 2>&1

    ########################################################################################################################
    ################################################## DEV CLUSTER #########################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

    nam=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get workloads -o json | jq --arg key "$TAP_WORKLOAD_NAME" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" == "$TAP_WORKLOAD_NAME" ]; then
      echo " ✓ Deleting Workload on $TAP_CLUSTER_DEV"
      tanzu app workload -n $TAP_DEVELOPER_NAMESPACE delete $TAP_WORKLOAD_NAME --yes > /tmp/error.log 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: failed to delete workload, please try manually"
        echo "       => tanzu app workload -n $TAP_DEVELOPER_NAMESPACE delete $TAP_WORKLOAD_NAME --yes"
        exit 1
      fi
    fi 

    echo " ✓ Delete the existing and recreat the developer namespace ($TAP_DEVELOPER_NAMESPACE)"
    cnt=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload 2>/dev/null | grep -c "$TAP_WORKLOAD_NAME") 
    #[ $cnt -gt 0 ] && kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $TAP_WORKLOAD_NAME > /dev/null 2>&1 && sleep 60
    [ $cnt -gt 0 ] && kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $TAP_WORKLOAD_NAME && sleep 60

    #createTAPNamespace $TAP_CONTEXT_DEV $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    createTAPNamespace $TAP_CONTEXT_DEV $TAP_DEVELOPER_NAMESPACE recreate > /dev/null 2>&1

    echo "   ▪ Adding Scan Policy (newsletter-scan-policy) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $TDHHOME/demos/tap-java-webapp/config/scan-policy.yaml > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to add scan policy, please try manually"
      echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $TDHHOME/demos/tap-java-webapp/config/scan-policy.yaml"
      exit
    fi

    echo "   ▪ Adding Pipline ($pipeline-notest) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $TDHHOME/demos/tap-java-webapp/config/pipeline-notest.yaml > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to add pipeline pipeline-notest, please try manually"
      echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $TDHHOME/demos/tap-java-webapp/config/pipeline-notest.yaml"
      exit
    fi

    if [ -d $HOME/workspace/$TDH_DEMO_GIT_REPO ]; then 
      echo " ✓ Deleted local git repository \$HOME/workspace/$TDH_DEMO_GIT_REPO"
      rm -rf $HOME/workspace/$TDH_DEMO_GIT_REPO
    fi

    # --- DELETE TAP DEMP REPO ---
    rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
    if [ "$rep" == "$TDH_DEMO_GIT_REPO" ]; then
      echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
      gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes >/dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: failed to delete github repository $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO, please try manually"
        echo "       => gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes"
        exit 1
      fi
    fi

    echo ""
    echo "Demo Setup successfuly deleted"
  fi

  if [ "$2" == "dev" ]; then
    cd $HOME
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

    # --- CREATE TDH_DEMO_GIT_REPO REPO ---
    rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
    if [ "$rep" != "$TDH_DEMO_GIT_REPO" ]; then
      echo " ✓ Create Github repository https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
      gh repo create $TDH_DEMO_GIT_REPO --public >/dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: failed to create github repository $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO, please try manually"
        echo "       => gh repo create $TDH_DEMO_GIT_REPO --public"
        exit 1
      fi
    else
      echo " ✓ Verify Github repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
    fi

    if [ ! -d $HOME/workspace/$TDH_DEMO_GIT_REPO/.git ]; then 
      cd $HOME/workspace
      echo " ✓ Clone Github Repository https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git to \$HOME/workspace/$TDH_DEMO_GIT_REPO"
      git -C $HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/${TDH_DEMO_GIT_REPO}.git > /dev/null 2>&1
    else
      echo " ✓ Verify Github Repository https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git to \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    fi

    if [ ! -f $HOME/workspace/$TDH_DEMO_GIT_REPO/pom.xml ]; then 
      echo " ✓ Generate TAP Demo Application $TDH_DEMO_GIT_REPO from the TAP Accelerator (tanzu-java-web-app)"
      rm -f /tmp/${TDH_DEMO_GIT_REPO}.zip
      tanzu accelerator generate tanzu-java-web-app --server-url https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} \
          --options "{\"projectName\":\"$TDH_DEMO_GIT_REPO\"}" --output-dir /tmp > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: failed to create create new application from TAP Accelerator, please try manually"
        echo "       => tanzu accelerator generate tanzu-java-web-app \\"
        echo "               --server-url https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} \\"
        echo "               --options '{\"projectName\":\"$TDH_DEMO_GIT_REPO\"}' --output-dir /tmp"
        exit 1
      fi

      echo " ✓ Unpack generated project in \$HOME/workspace"
      unzip /tmp/java-webapp.zip -d $HOME/workspace > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: failed tp unpack /tmp/java-webapp.zip, please try manually"
        echo "       => unzip /tmp/java-webapp.zip -d \$HOME/workspace"
        exit 1
      fi

      echo " ✓ Commit changes to Github repository: https://github.com/$TDH_DEMO_GITHUB_USER/${TDH_DEMO_GIT_REPO}.git"
      cd $HOME/workspace/${TDH_DEMO_GIT_REPO} 
      git add * ./.mvn ./.gitignore ./.tanzuignore> /dev/null 2>&1
      git commit -m "new files" > /dev/null 2>&1
      git push > /dev/null 2>&1
    else
      echo " ✓ Verify TAP Demo Applicaiton ($TDH_DEMO_GIT_REPO) under \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    fi

    nam=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get workloads -o json | jq --arg key "$TAP_WORKLOAD_NAME" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "$TAP_WORKLOAD_NAME" ]; then
      echo " ✓ Deploy the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME)"
      cd $HOME/workspace/$TAP_WORKLOAD_NAME
      tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE --local-path . --update-strategy replace --yes --tail --wait > /tmp/error.log 2>&1
      sleep 10
  
      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload $TAP_WORKLOAD_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break
        let i=i+1
        sleep 60
      done
        
      if [ "$stt" != "True" ]; then 
        echo "ERROR: Failed to deploy $TAP_WORKLOAD_NAME on the $TAP_CLUSTER_DEV, please try manually"
        echo "       => tanzu -n $TAP_DEVELOPER_NAMESPACE apps workload get $TAP_WORKLOAD_NAME"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f /tmp/${TAP_WORKLOAD_NAME}-gitops.yaml"
        exit 1
      fi
    else
      stt=$(curl https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} 2>/dev/null | grep -c "Greetings") 
      if [ $stt -gt 0 ]; then 
        echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) - Deployment was succesful, application is running"
      else
        echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) - Deployment was not succesful, please investige manually"
      fi
    fi

    echo "   $LINE"
    tanzu -n $TAP_DEVELOPER_NAMESPACE apps workload list | sed 's/^/   /g'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"

    echo " ✓ Verify the Deployment Accesability"
    echo "   (curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN})"
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    curl -w "\n" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} 2>/dev/null | sed 's/^/   /g'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"

    echo "" 
    echo "Demo Setup successfuly deployed"
  fi

  if [ "$2" == "regops" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    # --- VERIFY IF DEV HAS BEEN DEPLOYED ---
    kubectl config use-context $TAP_CONTEXT_DEV > /dev/null
    cnt=$(tanzu apps workload list -A | egrep -c "$TAP_WORKLOAD_NAME")
    if [ $cnt -eq 0 ]; then 
        echo "ERROR: The 'regops' setup is depending on the 'dev' deployment, so please"
        echo "       deploy 'tdh setup dev' first."
        exit 0
    fi

    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/NAMESPACE/${TAP_DEVELOPER_NAMESPACE}-regops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops.yaml

    ########################################################################################################################
    ######################################### OPS CLUSTER ##################################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null

    nam=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get workloads -o json | jq --arg key "$TAP_WORKLOAD_NAME" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "$TAP_WORKLOAD_NAME" ]; then
      echo " ✓ Deploy the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME)"
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_NAME}-regops.yaml > /dev/null 2>&1
      sleep 10
  
      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get workload $TAP_WORKLOAD_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break 
        let i=i+1
        sleep 60
      done
        
      if [ "$stt" != "True" ]; then 
        echo "ERROR: Failed to deploy $TAP_WORKLOAD_NAME on the $TAP_CLUSTER_DEV, please try manually"
        echo "       => tanzu -n ${TAP_DEVELOPER_NAMESPACE}-regops apps workload get $TAP_WORKLOAD_NAME"
        echo "       => kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_NAME}-regops.yaml"
        exit 1 
      fi 
    else 
      stt=$(curl https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} 2>/dev/null | grep -c "Greetings") 
      if [ $stt -gt 0 ]; then                  
        echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) - Deployment was succesful, application is running"
      else                                     
        echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) - Deployment was not succesful, please investige manually"
      fi 
    fi
    
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    tanzu -n ${TAP_DEVELOPER_NAMESPACE}-regops apps workload list | sed 's/^/   /g'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"

    ########################################################################################################################
    ######################################### RUN CLUSTER ##################################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null 

    # --- STAGE TEST ---
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TDH_STAGE_TEST}/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml

    echo " ✓ Create a rmote Branch 'prod' basing on the 'main' branch"
    cd $HOME/workspace/${TAP_WORKLOAD_NAME}-config
    git switch main > /dev/null 2>&1
    git pull > /dev/null 2>&1
    git checkout -b prod > /dev/null 2>&1
    git push --set-upstream origin prod > /dev/null 2>&1

    nam=$(kubectl get Deliverable -n $TDH_STAGE_TEST -o json | jq -r --arg key "$TAP_WORKLOAD_NAME" '.items[].metadata | select(.name == $key).name') 
    if [ "$nam" != "$TAP_WORKLOAD_NAME" ]; then
      echo " ✓ Deploy the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace: $TDH_STAGE_TEST"
      kubectl -n $TDH_STAGE_TEST apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml > /dev/null 2>&1
      sleep 10

      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n $TDH_STAGE_TEST get Deliverable $TAP_WORKLOAD_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break
        let i=i+1
        sleep 60
      done
    fi
#echo "   kubectl -n $TDH_STAGE_TEST apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml"

    stt=$(curl https://${TAP_WORKLOAD_NAME}-${TDH_STAGE_TEST}.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} 2>/dev/null | grep -c "Greetings")
    if [ $stt -gt 0 ]; then
      echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace ($TDH_STAGE_TEST) - Deployment was succesful, application is running"
    else
      echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace ($TDH_STAGE_TEST) - Deployment was not succesful, please investige manually"
    fi

    # --- STAGE PROD ---
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TDH_STAGE_PROD}/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml

    nam=$(kubectl get Deliverable -n $TDH_STAGE_PROD -o json | jq -r --arg key "$TAP_WORKLOAD_NAME" '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "$TAP_WORKLOAD_NAME" ]; then
      echo " ✓ Deploy the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace: $TDH_STAGE_PROD"
      kubectl -n $TDH_STAGE_PROD apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml > /dev/null 2>&1
      sleep 10

      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n $TDH_STAGE_PROD get Deliverable $TAP_WORKLOAD_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break
        let i=i+1
        sleep 60
      done
    fi
#echo "   kubectl -n $TDH_STAGE_PROD apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml"
  
    stt=$(curl https://${TAP_WORKLOAD_NAME}-${TDH_STAGE_PROD}.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} 2>/dev/null | grep -c "Greetings")
    if [ $stt -gt 0 ]; then
      echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace ($TDH_STAGE_PROD) - Deployment was succesful, application is running"
    else 
      echo " ✓ Verify the TAP Demo Applicaiton ($TAP_WORKLOAD_NAME) in Namespace ($TDH_STAGE_PROD) - Deployment was not succesful, please investige manually"
    fi

    echo " ✓ Manually verify deployments"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-${TDH_STAGE_TEST}.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-${TDH_STAGE_PROD}.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"



#kkkkkkkk

  fi

  if [ "$2" == "gitops" ]; then
    echo " ✓ Apply workload file for ($TAP_WORKLOAD_BACKEND_NAME) on the OPS Cluster"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TAP_DEVELOPER_NAMESPACE}-gitops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml > /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml

    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml >/dev/null 2>&1
    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml --wait  >/dev/null 2>&1
    sleep 10

    i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
      stt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops get workload $TAP_WORKLOAD_BACKEND_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status') 
      [ "$stt" == "True" ] && break
      let i=i+1
      sleep 30
    done

    if [ "$stt" != "True" ]; then 
      echo "ERROR: Failed to deploy $TAP_WORKLOAD_BACKEND_NAME on the $TAP_CLUSTER_OPS, please try manually"
      echo "       => tanzu -n ${TAP_DEVELOPER_NAMESPACE}-gitops apps workload get $TAP_WORKLOAD_BACKEND_NAME"
      echo "       => kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml"
      exit 1
    fi

    echo " ✓ Apply workload file for ($TAP_WORKLOAD_FRONTEND_NAME) on the OPS Cluster"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TAP_DEVELOPER_NAMESPACE}-gitops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml > /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml
    
    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml >/dev/null 2>&1
    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops apply -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml --wait  >/dev/null 2>&1
    sleep 10

    i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
      stt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops get workload $TAP_WORKLOAD_FRONTEND_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
      [ "$stt" == "True" ] && break
      let i=i+1
      sleep 30
    done

    if [ "$stt" != "True" ]; then
      echo "ERROR: Failed to deploy $TAP_WORKLOAD_FRONTEND_NAME on the $TAP_CLUSTER_OPS, please try manually"
      echo "       => tanzu -n $TAP_WORKLOAD_FRONTEND_NAME apps workload get $TAP_WORKLOAD_BACKEND_NAME"
      echo "       => kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops apply -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml"
      exit 1
    fi

    ########################################################################################################################
    ######################################### RUN CLUSTER ##################################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null

    createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-gitops

    nam=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops get ClassClaim -o json | jq --arg key "newsletter-db" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "newsletter-db" ]; then
      echo " ✓ Create Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-regops"
      tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
    else
      echo " ✓ Verify Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-gitops"
    fi


    echo "--------------------------------------------------------------------------------------------------------------------------"
    tanzu -n ${TAP_DEVELOPER_NAMESPACE}-gitops apps workload list 
    echo "--------------------------------------------------------------------------------------------------------------------------"

    echo ""
    echo "Demo Setup for '$TAP_WORKLOAD_BACKEND_NAME' and '$TAP_WORKLOAD_FRONTEND_NAME' completed"
  fi
fi

if [ "$1" == "guide" ]; then 
  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  # https://devopscube.com/checkout-git-pull-request/
  # git push origin -d bugfix/JRA411-application-title

  if [ "$2" == "" ]; then
    echo "tdh guide dev_AcceleratorCLI          ## New project woth TAP Accelerator (CLI)"
    echo "tdh guide dev_AcceleratorVSCode       ## New project woth TAP Accelerator (VSCode)"
    echo "tdh guide dev_PullRequestCLI          ## Modify app with Git pull Request (CLI)"
    echo "tdh guide dev_PullRequestVSCode       ## Modify app with Git pull Request (GitHub)"
    echo "tdh guide ops_KnativeDebugging        ## Investigate long startup times in PROD/TEST"
    echo "tdh guide regops                      ## Configure nd deploy Stage (TEST) and (PROD)"
  fi

  if [ "$2" == "ops_KnativeDebugging" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    echo "1.)  Investigate the long application startup times for TEST and PROD"
    echo "     ----------------------------------------------------------------"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}      ## Dev"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "     NOTICE: Accessing the 'test' and 'prod' instances are rather slow (10s)"
    echo ""
    echo "2.)  Take a closure look on the knative applicaiton deployment"
    echo "     ----------------------------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_RUN"
    echo "     kn service list -A"
    echo "     kn service list -A"
    echo "     kn revision list -A"
    echo "     kn route list -A"
    echo ""
    echo "     ## Debug the java-webapp (TEST) Instance"
    echo "     => Terminal-1: Debug knativ"
    echo "        rev_test=\$(kn revision list -n test | sed '1d' | head -1 | awk '{ print \$1 }')"
    echo "        watch kn revision describe \$rev_test -n test"
    echo "     => Terminal-2: Test request"
    echo "        curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo ""
    echo "     ## Debug the java-webapp (PROD) Instance"
    echo "     => Terminal-1: Debug knativ"
    echo "        rev_prod=\$(kn revision list -n prod | sed '1d' | head -1 | awk '{ print \$1 }')"
    echo "        watch kn revision describe \$rev_prod -n prod"
    echo "     => Terminal-2: Test request"
    echo "        curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "     NOTICE: You will notice that the knative command: 'kn revision describe <instance>' shows 'No-"
    echo ""

    echo "5.)  Modify the Workload configuration in /tmp/${TAP_WORKLOAD_NAME}-regops.yaml"
    echo "     (autoscaling.knative.dev/minScale: \"0\" =>  autoscaling.knative.dev/minScale: \"1\")"
    echo ""
    bat --style snip,header,rule,numbers  /tmp/${TAP_WORKLOAD_NAME}-regops.yaml 
    echo ""
    echo "     ## Deploy the changes on the OPS Cluster"
    echo "     kubectl config use-context $TAP_CONTEXT_OPS"
    echo "     kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_NAME}-regops.yaml"
    echo ""
    echo "     # Retry to access the application on TEST and PROD"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "     NOTICE: Now you should see a difference on 'test' with faster respons times as the container"
    echo "             are aleady started in advance. The prod instance has not changed yet."
    echo ""
    echo "5.)  DevOps merges changes 'main' branch into prod (usually needs approval)"
    echo "     cd \$HOME/workspace/${TDH_DEMO_GIT_REPO}-config"
    echo "     git branch -a          # Show all local and remote branches"
    echo "     git switch main        # Switch to 'main' branch with latest changes"
    echo "     git pull               # Get lates changes from main branch (dev/test)"
    echo "     git switch prod        # Switch to prod branch"
    echo "     git merge main         # Merge changes to the prod branch"
    echo "     git push --set-upstream origin prod"
    echo ""
    echo "     # Retry to access the application on PROD"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
  fi

  if [ "$2" == "dev_PullRequestCLI" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    # https://www.thegeekdiary.com/gh-pr-merge-merge-github-pull-requests/
    # git branch -d bugfix/JRA411-application-title
    # git push --set-upstream origin bugfix/JRA411-application-title
    # gh pr merge -r --delete-branch
    # git push origin --delete bugfix/JRA411-application-title

    echo "1.)  Show Jira Ticket: JRA_411 to the audience"
    echo "     -----------------------------------------"
    echo "     https://raw.githubusercontent.com/pivotal-sadubois/tanzu-demo-hub/main/demos/tap-java-webapp/images/multistage.pdf"
    echo ""
    echo "2.)  Create a new branch for the requested bugfix"
    echo "     --------------------------------------------"
    echo "     cd \$HOME/workspace/${TDH_DEMO_GIT_REPO}"
    echo "     git checkout -b \"bugfix/JRA411-application-title\""
    echo "     git branch"
    echo ""
    echo "3.)  Change text of the Welcome Message 'Greetings from Spring Boot + Tanzu!'"
    echo "     ------------------------------------------------------------------------"
    echo "     vi src/main/java/com/example/springboot/HelloController.java"
    echo ""
    echo "4.)  Add the change to git and commit the change"
    echo "     -------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_DEV"
    echo "     tanzu apps workload apply --file config/workload.yaml \\"
    echo "           --namespace $TAP_DEVELOPER_NAMESPACE --local-path . \\"
    echo "           --update-strategy replace --yes --tail --wait"
    echo "     tanzu apps workload get $TAP_WORKLOAD_NAME --namespace $TAP_DEVELOPER_NAMESPACE"
    echo ""
    echo "5.)  Verify the change on the Web Page title"
    echo "     ---------------------------------------"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}      ## Dev"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "6.)  Add the change to git and commit the change"
    echo "     -------------------------------------------"
    echo "     git add src/main/java/com/example/springboot/HelloController.java"
    echo "     git commit -m \"bugfix/JRA411-application-title\""
    echo "     git push --set-upstream origin bugfix/JRA411-application-title"
    echo ""
    echo "7.)  Create a Pull Request to merge the changes into main"
    echo "     -------------------------------------------"
    echo "     gh pr create --fill"
    echo "     gh pr list"
    echo "     gh pr merge -r --delete-branch"
    echo "     git remote update origin --prune"
    echo ""
    echo "8.)  Verify the Application changes on Deployments and Test"
    echo "     ------------------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_RUN"
    echo "     watch kn revision list -A"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}      ## Dev"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "9.)  DevOps merges changes 'main' branch into prod (usually needs approval)"
    echo "     ----------------------------------------------------------------------"
    echo "     cd \$HOME/workspace/${TDH_DEMO_GIT_REPO}-config"
    echo "     git branch -a          # Show all local and remote branches"
    echo "     git switch main        # Switch to 'main' branch with latest changes"
    echo "     git pull               # Get lates changes from main branch (dev/test)"
    echo "     git switch prod        # Switch to prod branch"
    echo "     git merge main         # Merge changes to the prod branch"
    echo "     git push --set-upstream origin prod"
    echo ""
    echo "20.) Verify the Application on all three Stages"
    echo "     ------------------------------------------"
    echo "     watch kn revision list -A"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}      ## Dev"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
    echo ""
    echo "kapp -n prod inspect -a java-webapp.app"
#kubectl get services -n knative-serving
#kn service list -A
#kn service describe java-webapp -n prod
#kn route list -A
#kn revision list -A
# watch kn revision describe java-webapp-00002 -n prod
# curl -w "\n" https://java-webapp-prod.run.tapmc.tanzudemohub.com
    echo ""



  fi

  if [ "$2" == "dev_AcceleratorCLI" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    echo "Create a new Application basing on the TAP Accelerators project 'tanzu-java-web-app' by CLI"
    echo "-------------------------------------------------------------------------------------------"
    echo ""
    echo "1.)  Create Demo Repository (jave-webapp) and clone it to the local \$HOME/workspace/${TDH_DEMO_GIT_REPO} directory"
    echo "     --------------------------------------------------------------------------------------------------------------"
    echo "     ## On the Gitub Web Portal"
    echo "     https://withub.com => Login as user $TDH_DEMO_GITHUB_USER => Repositories => Create repository: jave-webapp (public)"
    echo ""
    echo "     ## With the Tanzu CLI"
    echo "     echo \"$TDH_DEMO_GITHUB_TOKEN\" | gh auth login -p https --with-token"
    echo "     gh repo create $TDH_DEMO_GIT_REPO --public"
    echo ""
    echo "2.)  Clone the repository to the local $HOME/workspace directory"
    echo "     -----------------------------------------------------------"
    echo "     git -C \$HOME/workspace clone \\"
    echo "            https://$TDH_DEMO_GITHUB_TOKEN@github.com/$TDH_DEMO_GITHUB_USER/${TDH_DEMO_GIT_REPO}.git"
    echo ""
    echo "3.)  Create Demo Application (jave-webapp) from a TAP Accelerator"
    echo "     ------------------------------------------------------------"
    echo "     ## With the Tanzu CLI"
    echo "     kubectl config use-context $TAP_CONTEXT_DEV"
    echo "     tanzu accelerator list --server-url https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"
    echo "     tanzu accelerator generate tanzu-java-web-app \\"
    echo "             --server-url https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN} \\"
    echo "             --options '{\"projectName\":\"$TDH_DEMO_GIT_REPO\"}' --output-dir /tmp"
    echo "     unzip -d \$HOME/workspace /tmp/${TDH_DEMO_GIT_REPO}.zip"
    echo ""
    echo "4.)  Add application files to git and push to the github repository"
    echo "     --------------------------------------------------------------"
    echo "     cd \$HOME/workspace/${TDH_DEMO_GIT_REPO}"
    echo "     git add * ./.mvn ./.gitignore ./.tanzuignore"
    echo "     git commit -m \"new files\" && git push"
    echo ""
    echo "5.)  Manually deploy the Application"
    echo "     -------------------------------"
    echo "     cd \$HOME/workspace/${TDH_DEMO_GIT_REPO}"
    echo "     tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE --local-path . --update-strategy replace --yes --tail --wait"
    echo "     tanzu apps workload get $TAP_WORKLOAD_NAME --namespace $TAP_DEVELOPER_NAMESPACE"
    echo ""

sdubois$ kubectl -n java-webapp  get ServerlessService java-webapp-00003 -o yaml
  fi

  if [ "$2" == "dev_AcceleratorVSCode" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    echo "Create a new TAP Accelerators project based on 'tanzu-java-web-app' within VSCode"
    echo "---------------------------------------------------------------------------------"
    echo "1.)  Create Demo Application (jave-webapp) from a TAP Accelerator"
    echo "     ## Microsoft VSCode (Tanzu Accelerator Plugin required)"
    echo "        VSCode => Accelerators, Choose 'tanzu-java-web-app'"
    echo "        1.1) Configure the Accelerator"
    echo "             - Name .............................: $TDH_DEMO_GIT_REPO"
    echo "             - Build Tool .......................: (Maven) https://maven.apache.org (default)"
    echo "             - Spring Boot version ..............: Spring Boot 2.7 (default)"
    echo "               Support native GraalVM builds ....: no (disbled)"
    echo "             - Java version to use ..............: Java 11"
    echo "               Include Build Tool wrapper support: yes (enabled)"
    echo "               Include .devcontainer.json .......: no (disabled)"
    echo "        1.2) Git repository"
    echo "             - Create a new repository ..........: yes (enabled)"
    echo "             - Github Access Token ..............: $TDH_DEMO_GITHUB_TOKEN"
    echo "             - Host .............................: github.com"
    echo "             - Owner ............................: $TDH_DEMO_GITHUB_USER"
    echo "             - Repository Name ..................: $TDH_DEMO_GIT_REPO"
    echo ""
    echo "2.)  Create project and store it on the local repository"
    echo "     ---------------------------------------------------"
    echo "     ▪ Local Repository Directory: \$HOME/workspace"
    echo "     ▪ Source Control: Choose upload to GitHub"
    echo ""
    echo "3.)  Open The Tanzu Application Platform (TAP)"
    echo "     -----------------------------------------"
    echo "     ▪ Register the 'newsletter' app as Catalog Entity"
    echo "       TAP Gui (Home) -> Register Entity -> Repository Url: "
    echo "       https://github.com/pivotal-sadubois/newsletter/blob/main/catalog/catalog-info.yaml"
    echo ""
    echo "6.)  Deploy the App (jave-webapp)"
    echo "     ----------------------------"
    echo "     ▪ Create branch with VSCode"
    echo "       VSCode -> Explorer -> Newsletter Subscription -> config/workload.yaml "
    echo "       (right mouse button) -> Tanzu Live Update"
    echo ""
    echo "     ▪ Create branch with CLI"
    echo "       tanzu apps workload apply \\"
    echo "          --file \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME/config/workload.yaml \\"
    echo "          --namespace $TAP_DEVELOPER_NAMESPACE \\"
    echo "          --source-image $HARBOR/library/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "          --local-path \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "          --live-update --tail --update-strategy replace --debug --yes"
    echo ""
    echo "       tanzu apps workload get $TAP_WORKLOAD_NAME --namespace $TAP_DEVELOPER_NAMESPACE"
  fi

  if [ "$2" == "regops" ]; then
    DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
    DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
    HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/NAMESPACE/${TAP_DEVELOPER_NAMESPACE}-regops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops.yaml

    # --- STAGE TEST ---
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TDH_STAGE_TEST}/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_TEST}-deliverable.yaml

    # --- STAGE PROD ---
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TDH_STAGE_PROD}/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml > /tmp/${TAP_WORKLOAD_NAME}-regops-${TDH_STAGE_PROD}-deliverable.yaml

    clear
    echo "Configure FluxCD on the TAP Operation Cluster (OPS) to monitor the "
    echo "GIT Repository ($TDH_DEMO_GIT_REPO) for new pull requests"
    echo "---------------------------------------------------------"
    echo "IMPORTAND: Make shure thaa application ($TDH_DEMO_GIT_REPO) has been deployed "
    echo "           by either 'tdh guide dev_AcceleratorCLI' or 'tdh guide dev_AcceleratorVSCode?'"
    echo ""
    echo "1.)  Apply workload file (/tmp/${TAP_WORKLOAD_NAME}-regops.yaml) for the"
    echo "     Applicaiton ($TAP_WORKLOAD_NAME) on the OPS Cluster"
    echo "     ---------------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_OPS"
    echo ""
    bat --style snip,header,rule,numbers  /tmp/${TAP_WORKLOAD_NAME}-regops.yaml 
    echo ""
    echo "     kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_NAME}-regops.yaml"
    echo ""
    echo "2.)  Veriy the deployment"
    echo "     --------------------"
    echo "     tanzu apps workload -n ${TAP_WORKLOAD_NAME}-regops list"
    echo ""
    echo "3.)  Create a new Branch for 'prod' in the ${TAP_WORKLOAD_NAME}-config repository"
    echo "     ------------------------------------------------------------"
    echo "     ## Create a new 'prod' branch (GitHub)"
    echo "     Github => Repository: ${TAP_WORKLOAD_NAME}-config => Click on Branch => New Branch: prod"
    echo ""
    echo "     ## Create a new 'prod' branch CLI"
    echo "     cd \$HOME/workspace/${TAP_WORKLOAD_NAME}-config"
    echo "     git pull"
    echo "     git checkout -b prod"
    echo "     git push --set-upstream origin prod"
    echo ""
    echo "4.)  Verify Application Deployment with knative utility"
    echo "     --------------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_RUN"
    echo "     kn service list -A"
    echo "     kn service list -A" 
    echo "     kn revision list -A"
    echo "     kn route list -A"
    echo ""    
    echo "5.)  Deploy the Deliverable to the TAP RUN Production Cluster"
    echo "     --------------------------------------------------------"
    echo "     kubectl config use-context $TAP_CONTEXT_RUN"
    echo ""
    bat --style snip,header,rule,numbers  /tmp/${TAP_WORKLOAD_NAME}-regops-test-deliverable.yaml
    echo ""
    echo "     kubectl -n $TDH_STAGE_TEST apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-test-deliverable.yaml"
    echo ""
    bat --style snip,header,rule,numbers  /tmp/${TAP_WORKLOAD_NAME}-regops-prod-deliverable.yaml
    echo ""
    echo "     kubectl -n $TDH_STAGE_PROD apply -f /tmp/${TAP_WORKLOAD_NAME}-regops-prod-deliverable.yaml"
    echo ""
    echo "6.)  Investigate the long application startup times for TEST and PROD"
    echo "     ----------------------------------------------------------------"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}      ## Dev"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-test.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Test"
    echo "     curl -w \"\\n\" https://${TAP_WORKLOAD_NAME}-prod.run.${DNS_SUBDOMAIN}.${DNS_DOMAIN} ## Prod"
  fi

fi

if [ "$1" == "init" ]; then 
  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  if [ -f $HOME/.tdh/tdh_demo_name.cfg -a -f $HOME/.tdh/tdh_demo_config.cfg ]; then
    [ "$TDH_DEMO_NAME" == "" -a -f $HOME/.tdh/tdh_demo_name.cfg ] && export TDH_DEMO_NAME=$(cat $HOME/.tdh/tdh_demo_name.cfg)
    [ "$TDH_DEMO_CONFIG" == "" -a -f $HOME/.tdh/tdh_demo_config.cfg ] && export TDH_DEMO_CONFIG=$(cat $HOME/.tdh/tdh_demo_config.cfg)
  
    if [ "$2" != "--force" ]; then
      echo "ERROR: TDH Demo environment is currently active with demo: $TDH_DEMO_NAME on the TDH Environment: $TDH_DEMO_CONFIG."
      echo "       used 'tdh init --force' the reinitiate the demo or 'tdh clean' to delete the demo"
      exit
    fi
  fi

  cat $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/kubeconfig_*.yaml > $HOME/.kube/config
  echo " ✓ Generating kubeconfig in \$HOME/.kube/config with '$TDH_SERVICE_LUSTER' and '$TAP_DEVELOPER_NAMESPACE' namespace as default context"
  echo "   Default Context will set to '$TAP_CONTEXT_DEV with '$TAP_DEVELOPER_NAMESPACE' as namespace'"
  echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
  kubectl --kubeconfig=$HOME/.kube/config config get-contexts | sed 's/^/   /g'
  echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"

  if [ ! -d $HOME/PythonDev ]; then 
    echo " ✓ Seting up temporary Python emvironment and module dependancies"
    python3 -m venv $HOME/PythonDev
    source $HOME/PythonDev/bin/activate
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    pip3 install -r scripts/requirements.txt | sed 's/^/   /'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
  else
    source $HOME/PythonDev/bin/activate
    echo " ✓ Verify temporary Python emvironment and module dependancies"
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    pip3 install -r scripts/requirements.txt | sed 's/^/   /'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
  fi

  # --- SETUP DEMO LOCK FILES ---
  [ ! -d $HOME/.tdh ] && mkdir -p $HOME/.tdh
  echo "$TDH_DEMO_NAME" > $HOME/.tdh/tdh_demo_name.cfg
  echo "$TDH_DEMO_CONFIG" > $HOME/.tdh/tdh_demo_config.cfg

  echo ""
  echo "Demo Initialization successfuly completed"
fi

if [ "$1" == "clean" ]; then 
  echo " ✓ Verify github authorization for user '$TDH_DEMO_GITHUB_USER'"
    
  gh_token=$(gh auth token)
  if [ "$gh_token" == "" -o "$gh_token" != "$TDH_DEMO_GITHUB_TOKEN" ]; then
    echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: Failed to login Github with the 'gh' utility, please try manually"
      echo "       => echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token"
      exit     
    fi
  fi

  # --- DELETE TAP DEMP REPO ---
  rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "$TDH_DEMO_GIT_REPO" ]; then
    echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
    gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes >/dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then 
      echo "ERROR: failed to delete github repository $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO, please try manually"
      echo "       => gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes"
      exit 1
    fi
  fi

  # --- DELETE GITOPS CARTOGRAPHER REPO ---
  rep=$(gh repo list --json name | jq -r --arg key $TDH_CARTO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "$TDH_CARTO_GIT_REPO" ]; then
    echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO"
    gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO --yes >/dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then 
      echo "ERROR: failed to delete github repository $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO, please try manually"
      echo "       => gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO --yes"
      exit 1
    fi
  fi
  
  if [ -d $HOME/workspace/$TDH_DEMO_GIT_REPO ]; then 
    echo " ✓ Deleted local git repository \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    rm -rf $HOME/workspace/$TDH_DEMO_GIT_REPO
  fi

  if [ -d $HOME/workspace/$TDH_CARTO_GIT_REPO ]; then 
    echo " ✓ Deleted local git repository \$HOME/workspace/$TDH_CARTO_GIT_REPO"
    rm -rf $HOME/workspace/$TDH_CARTO_GIT_REPO
  fi


  echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_DEV)"
  kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

  #for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null | jq -r '.items[].metadata.name'); do
  #  echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
  #  kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
  #  if [ $ret -ne 0 ]; then                      
  #    echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
  #    echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
  #    exit
  #  fi
  #done

  for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload -o json 2>/dev/null | jq -r '.items[].metadata.name'); do
    echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$? 
    if [ $ret -ne 0 ]; then        
      echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
      exit
    else
      sleep 60
    fi
  done

  kubectl delete ns $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

#  if [ "$TDH_DEPLOYMENT_TYPE"  == "tap-multicluster" ]; then
#    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_OPS)"
#    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
#
#    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
#      echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#      kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
#      if [ $ret -ne 0 ]; then        
#        echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
#        exit
#      fi
#    done 
#
#    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
#      echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#       kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$?
#      if [ $ret -ne 0 ]; then  
#        echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
#        exit
#      fi
#    done
#
#    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
#    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
#
#    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_RUN)"
#    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null
#
#    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
#      echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#      kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
#      if [ $ret -ne 0 ]; then
#        echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
#        exit
#      fi
#    done
#
#    for n in $(kubectl -n $n get workload -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
#      echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#       kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$?
#      if [ $ret -ne 0 ]; then
#        echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
#        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
#        exit
#      fi
#    done
#
#    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
#    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
#  fi

  # --- CLEANING UP LOCK FILES ---
  rm -f $HOME/.tdh/tdh_demo_name.cfg $HOME/.tdh/tdh_demo_config.cfg

  echo ""
  echo "Demo cleanup successfuly completed"
fi

if [ "$1" == "git" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "git -C $HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
  echo "https://github.com/$TDH_DEMO_GITHUB_USER/newsletter/blob/main/catalog/catalog-info.yaml"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "service-class" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "tanzu service class list"
  echo "tanzu service class get postgresql-unmanaged"
  echo "tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n newsletter"
  echo "tanzu services class-claims get newsletter-db --namespace newsletter"
  echo "tanzu services class-claims delete newsletter-db --namespace newsletter -y"
  echo "kubectl get pods -n $(kubectl get ns | grep newsletter-db | awk '{ print $1 }')"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "tap" ]; then 
#  echo "kubectl apply -f ~/workspace/newsletter/newsletter-subscription/config/newsletter-scan-policy.yaml -n newsletter"
#  echo "kubectl apply -f ~/workspace/newsletter/newsletter-subscription/config/pipeline-notest.yaml -n newsletter"

  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "kubectl apply -f \$HOME/workspace/newsletter/newsletter-subscription/config/newsletter-scan-policy.yaml -n newsletter"
  echo "kubectl apply -f \$HOME/workspace/newsletter/newsletter-subscription/config/pipeline-notest.yaml -n newsletter"
  echo "kubectl apply -f \$HOME/workspace/newsletter/newsletter-subscription/config/pipeline-test.yaml -n newsletter"
  echo ""
  echo "# -- DEPLOY FROM GITHUB ---"
  echo "tanzu apps workload create newsletter-subscription --git-repo https://github.com/sdubois-tapdemo/newsletter \\"
  echo "  --sub-path newsletter-subscription --git-branch main --type web --label app.kubernetes.io/part-of=newsletter --yes -n newsletter"
  echo ""
  echo "# --- DEPLOY FROM LOCAL GIT ---"
  echo "tanzu apps workload apply --file \$HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml --namespace newsletter \\"
  echo "  --source-image harbor.apps.tap.tanzudemohub.com/library/newsletter --debug --yes \\"
  echo "  --local-path \$HOME/workspace/newsletter/newsletter-subscription --live-update --tail --update-strategy replace "
  echo ""
  echo "tanzu apps workload apply --file \$HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml --namespace newsletter \\"
  echo "  --source-image harbor.apps.tap.tanzudemohub.com/library/newsletter --local-path \$HOME/workspace/newsletter/newsletter-subscription --yes"
  echo ""
  echo "tanzu apps workload tail newsletter-subscription --namespace newsletter --timestamp --since 1h"
  echo "tanzu apps workload get newsletter-subscription --namespace newsletter"
  echo "tanzu apps workload list -n newsletter"
  echo "tanzu apps workload get newsletter-subscription -n newsletter -y"
  echo "tanzu apps workload delete newsletter-subscription -n newsletter -y"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "ClusterSupplyChain" -o "$1" == "clustersupplychain" -o "$1" == "cluster-supply-chain" ]; then
  echo "############################## $2 ##############################"

  [ "$2" == "" ] && kubectl get ClusterSupplyChain && exit
  for n in $(kubectl get ClusterSupplyChain $2 -o json | jq -r '.spec.resources[].name'); do
    echo "=> Ressource: $n"

    kubectl get ClusterSupplyChain $2 -o json | jq --arg key "$n" -r '.spec.resources[] | select(.name == $key)' > /tmp/out.json
    first=0
    for nn in $(jq -r '.params[].name' /tmp/out.json 2>/dev/null); do
      if [ $first -eq 0 ]; then
        echo "                Parameter: $nn"
        first=1
      else
        echo "                           $nn"
      fi
    
      jq -r --arg key "$nn" '.params[] | select(.name == $key)' /tmp/out.json | \
      jq 'if (.value) then {"ca_cert_data": .value.ca_cert_data,"repository": .value.repository, "server": .value.server } else . end' | \
      sed -e 's/certificate:.*$/<CERTIFICATE>"/g' -e 1d -e '$d' -e 's/"//g' -e 's/,$//' -e 's/^  /                             - /g'
    done 
  
    echo "                templateRef:"
    jq '.templateRef' /tmp/out.json | \
    sed -e 's/certificate:.*$/<CERTIFICATE>"/g' -e 1d -e '$d' -e 's/"//g' -e 's/,$//' -e 's/^  /                               /g' -e 's/  kind/- kind/g' -e 's/  name/- name/g'
  done
fi 


exit

