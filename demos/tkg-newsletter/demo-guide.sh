#!/bin/bash
# ############################################################################################
# File: ........: demo-guide.sh
# Language .....: bash 
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Newsletter Demo Guide
# ############################################################################################
# https://newsletter-subscription.dev.tap.tanzudemohub.com/swagger-ui/index.html
# curl https://newsletter-subscription.dev.tap.tanzudemohub.com/v3/api-docs | jq -r

TAP_DEVELOPER_NAMESPACE=newsletter
TAP_WORKLOAD_FRONTEND_NAME=newsletter-ui
TAP_WORKLOAD_FRONTEND_FILE=${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml
TAP_WORKLOAD_BACKEND_NAME=newsletter-subscription
TAP_WORKLOAD_BACKEND_FILE=${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml
TDH_DEMO_GIT_REPO=newsletter
TDH_CARTO_GIT_REPO=${TDH_DEMO_GIT_REPO}-config

#tanzu accelerator list --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator get tanzu-java-web-app --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator generate  tanzu-java-web-app --options '{"projecName":"tjwa"}' --server-url https://accelerator.dev.tapmc.v2steve.net

if [ "$1" == "" ]; then 
  echo "tdh init                               ## Initialize Newsletter Demo (Fork Git Repo)"
  echo "tdh setup                              ## Demo Setup"
  echo "tdh guide                              ## Show the Demo Guide"
  echo "tdh context,c [dev,ops,run,svc]        ## Set Kubernetes Context (dev,ops,svc,run)"
  echo "tdh supply-chain [gitops,devops]       ## OPS Supply Chain (gitops, regops)"
  echo "tdh service-class"
  echo "tdh git"
  echo "tdh tap"
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

  if [ "$2" == "delete" ]; then
    ########################################################################################################################
    ################################################## RUN CLUSTER #########################################################
    ########################################################################################################################
    if [ "$TAP_CLUSTER_RUN" != "" ]; then
      echo " ✓ Deleting Workload on $TAP_CLUSTER_RUN"
      kubectl config use-context $TAP_CONTEXT_RUN > /dev/null

      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete workload $TAP_WORKLOAD_BACKEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete workload $TAP_WORKLOAD_FRONTEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete classclaim newsletter-db > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete servicebinding newsletter-subscription-db > /dev/null 2>&1
      deleteNamespace ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
      createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1

      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete workload $TAP_WORKLOAD_FRONTEND_NAME            > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete workload $TAP_WORKLOAD_BACKEND_NAME             > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete deliverable $TAP_WORKLOAD_BACKEND_NAME          > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete servicebinding newsletter-subscription-db       > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete classclaim newsletter-db                        > /dev/null 2>&1
      deleteNamespace ${TAP_DEVELOPER_NAMESPACE}-regops                                                   > /dev/null 2>&1
      createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-regops                               > /dev/null 2>&1
    fi

    ########################################################################################################################
    ################################################## OPS CLUSTER #########################################################
    ########################################################################################################################
    if [ "$TAP_CLUSTER_RUN" != "" ]; then
      echo " ✓ Deleting Workload on $TAP_CLUSTER_OPS"
      kubectl config use-context $TAP_CONTEXT_OPS > /dev/null

      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete workload $TAP_WORKLOAD_BACKEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete workload $TAP_WORKLOAD_FRONTEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops delete classclaim newsletter-db > /dev/null 2>&1
      deleteNamespace ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
      createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1

      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete workload $TAP_WORKLOAD_BACKEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete workload $TAP_WORKLOAD_FRONTEND_NAME > /dev/null 2>&1
      kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete classclaim newsletter-db > /dev/null 2>&1
      deleteNamespace ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
      createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
    fi

    ########################################################################################################################
    ################################################## DEV CLUSTER #########################################################
    ########################################################################################################################
    echo " ✓ Deleting Workload on $TAP_CLUSTER_DEV"
    kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

    kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims newsletter-db > /dev/null 2>&1
    kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $TAP_WORKLOAD_BACKEND_NAME > /dev/null 2>&1
    kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $TAP_WORKLOAD_FRONTEND_NAME > /dev/null 2>&1
    deleteNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    createTAPNamespace $TAP_CONTEXT_DEV $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

    echo "   ▪ Adding Scan Policy (newsletter-scan-policy) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
    GITURL="https://raw.githubusercontent.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO/main/$TAP_WORKLOAD_BACKEND_NAME/config/newsletter-scan-policy.yaml"
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to add scan policy, please try manually"
      echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL"
      exit
    fi
  
    echo "   ▪ Adding Pipline ($pipeline-notest) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
    GITURL="https://raw.githubusercontent.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO/main/$TAP_WORKLOAD_BACKEND_NAME/config/pipeline-notest.yaml"
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to add pipeline pipeline-notest, please try manually"
      echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL"
      exit
    fi

    echo ""
    echo "Demo Setup successfuly deleted"
  fi

  if [ "$2" == "dev" ]; then
    kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

    cd $HOME/workspace
    echo " ✓ Clone/validate Git Repository https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git to \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    [ ! -d $HOME/workspace/$TDH_DEMO_GIT_REPO/.git ] && git -C $HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/${TDH_DEMO_GIT_REPO}.git > /dev/null 2>&1

    nam=$(kubectl get ns -o json | jq -r --arg key $TAP_DEVELOPER_NAMESPACE '.items[].metadata | select(.name == $key).name')
    if [ "$nam" == "" ]; then
      echo "   ▪ Creating Developer Namespace for '$TAP_DEVELOPER_NAMESPACE' on $TAP_CLUSTER_DEV"
      createNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    
      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
      kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
  
      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
      kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
  
      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
      dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE} docker-credentials
    
      echo "   ▪ Create Github SSH Access Secret (github-http-secret) in namespace ${TAP_DEVELOPER_NAMESPACE}"
      configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}
    else
      echo "   ▪ Verify Developer Namespace for '$TAP_DEVELOPER_NAMESPACE'"
    fi

    echo " ✓ Create Service Claim for PostgreSQL backend"
    nam=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get ClassClaim -o json | jq --arg key "newsletter-db" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "newsletter-db" ]; then 
      tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    fi

    echo " ✓ Deploy Newsletter Subscription Service"
    nam=$(kubectl -n newsletter get workloads -o json | jq --arg key "$TAP_WORKLOAD_BACKEND_NAME" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "$TAP_WORKLOAD_BACKEND_NAME" ]; then
      cd $HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME
      tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE --local-path . --update-strategy replace --yes --tail --wait > /tmp/error.log 2>&1
      sleep 10

      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload $TAP_WORKLOAD_BACKEND_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break
        let i=i+1
        sleep 60
      done

      if [ "$stt" != "True" ]; then
        echo "ERROR: Failed to deploy $TAP_WORKLOAD_BACKEND_NAME on the $TAP_CLUSTER_DEV, please try manually"
        echo "       => tanzu -n $TAP_DEVELOPER_NAMESPACE apps workload get $TAP_WORKLOAD_BACKEND_NAME"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml"
        exit 1
      fi
    fi

    echo " ✓ Deploy Newsletter UI Service"
    nam=$(kubectl -n newsletter get workloads -o json | jq --arg key "$TAP_WORKLOAD_FRONTEND_NAME" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "$TAP_WORKLOAD_FRONTEND_NAME" ]; then
      cd $HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_FRONTEND_NAME
      tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE --local-path . --update-strategy replace --yes --tail --wait > /tmp/error.log 2>&1
      sleep 10

      i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
        stt=$(kubectl -n newsletter get workload $TAP_WORKLOAD_FRONTEND_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
        [ "$stt" == "True" ] && break
        let i=i+1
        sleep 30
      done

      if [ "$stt" != "True" ]; then
        echo "ERROR: Failed to deploy $TAP_WORKLOAD_FRONTEND_NAME on the $TAP_CLUSTER_DEV, please try manually"
        echo "       => tanzu -n $TAP_WORKLOAD_FRONTEND_NAME apps workload get $TAP_WORKLOAD_BACKEND_NAME"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml"
        exit 1
      fi
    fi

    echo " ✓ Verify Newsletter Application Deployment"
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    tanzu -n $TAP_DEVELOPER_NAMESPACE apps workload list | sed 's/^/   /g'
    echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"

    myArray=("Frank:Zappa" "Paul:McCartney" "Alice:Cooper")

    TMPFILE=/tmp/tap_test_data.json; rm -f $TMPFILE
    echo "["                       > $TMPFILE

    i=1
    for n in ${myArray[@]}; do
      fn=$(echo $n | awk -F: '{ print $1 }')
      ln=$(echo $n | awk -F: '{ print $2 }')
      em="${fn}.${ln}@example.com"

      echo " {"                          >> $TMPFILE
      echo "  \"emailId\": \"$em\","     >> $TMPFILE
      echo "  \"firstName\": \"$fn\","   >> $TMPFILE
      echo "  \"lastName\": \"$ln\""     >> $TMPFILE

      [ $i -ne ${#myArray[@]} ] && str="," || str=""

      echo " }$str"                      >> $TMPFILE
      let i=i+1
    done

    echo "]"                             >> $TMPFILE

    ret=1; cnt=0
    while [ $ret -ne 0 -a $cnt -lt 5 ]; do
      curl -X 'GET' https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions > /dev/null 2>&1; ret=$? 
      [ $ret -eq 0 ] && break

      let cnt=cnt+1
      sleep 30
    done

    ids=$(curl -X 'GET' https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions -H 'accept: application/json' -H 'Content-Type: application/json' 2>/dev/null | \
          jq -r '.[].id' | wc -l | awk '{ print $1 }') 
    if [ $ids -lt 3 ]; then 
      echo " ✓ Load Test Data to the backend"
      echo "   (curl https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions 2>/dev/null | jq -r)"
      curl -X 'POST' https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions \
           -H 'accept: application/json' -H 'Content-Type: application/json' --data "@$TMPFILE" > /tmp/error.log 2>&1; ret=$?
      if [ $ret -eq 0 ]; then 
        echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
        curl -X 'GET' https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions -H 'accept: application/json' \
          -H 'Content-Type: application/json' 2>/dev/null | jq -r | sed 's/^/   /g'
        echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
      else
        echo "ERROR: failed to load testing data, please try manually"
        echo "curl -X 'POST' 'https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions' -H 'accept: application/json' -H 'Content-Type: application/json' --data \"@$TMPFILE\""
      fi
    else
      echo " ✓ Verify Test Data loaded to the backend"
      echo "   (curl https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions 2>/dev/null | jq -r)"

      echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
      curl -X 'GET' https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions -H 'accept: application/json' \
        -H 'Content-Type: application/json' 2>/dev/null | jq -r | sed 's/^/   /g'
      echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
    fi

    echo " ✓ Manually test functionality, enter following URL's into an Icognito Brwoser window"
    echo "   Verify the the Backend ($TAP_WORKLOAD_BACKEND_NAME)"
    echo "   => https://$TAP_WORKLOAD_BACKEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/actuator 2>/dev/null | jq -r"
    echo "" 
    echo "   Verify the the Frontend ($TAP_WORKLOAD_FRONTEND_NAME) in a Icognito Browder Window, or deleate the cache first"
    echo "   => https://$TAP_WORKLOAD_FRONTEND_NAME.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"
    echo ""
    echo "Demo Setup successfuly deleted"
  fi

  if [ "$2" == "regops" ]; then
    ########################################################################################################################
    ######################################### OPS CLUSTER ##################################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
    createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-regops

    nam=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get ClassClaim -o json | jq --arg key "newsletter-db" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "newsletter-db" ]; then
      echo " ✓ Create Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-regops"
      tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
    else
      echo " ✓ Verify Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-regops"
    fi

    echo " ✓ Apply workload file for ($TAP_WORKLOAD_BACKEND_NAME) on the OPS Cluster"
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TAP_DEVELOPER_NAMESPACE}-regops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_BACKEND_NAME}-regops.yaml > /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops.yaml

    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops delete -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops.yaml >/dev/null 2>&1
    kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops.yaml --wait  >/dev/null 2>&1
    sleep 10 

    i=1; stt="False"; while [ "$stt" != "True" -a $i -le 15 ]; do
      stt=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get workload $TAP_WORKLOAD_BACKEND_NAME -o json | jq -r '.status.conditions[] | select(.type == "Ready" and .reason == "Ready").status')
      [ "$stt" == "True" ] && break
      let i=i+1
      sleep 30
    done 

    if [ "$stt" != "True" ]; then
      echo "ERROR: Failed to deploy $TAP_WORKLOAD_BACKEND_NAME on the $TAP_CLUSTER_OPS, please try manually"
      echo "       => tanzu -n ${TAP_DEVELOPER_NAMESPACE}-regops apps workload get $TAP_WORKLOAD_BACKEND_NAME"
      echo "       => kubectl -n ${TAP_DEVELOPER_NAMESPACE}-gitops apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml"
      exit 1
    fi

    ########################################################################################################################
    ######################################### RUN CLUSTER ##################################################################
    ########################################################################################################################
    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null 
    createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-regops
    
    nam=$(kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops get ClassClaim -o json | jq --arg key "newsletter-db" -r '.items[].metadata | select(.name == $key).name')
    if [ "$nam" != "newsletter-db" ]; then
      echo " ✓ Create Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-regops"
      tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
    else
      echo " ✓ Verify Service Claim for PostgreSQL backend in namespace ${TAP_DEVELOPER_NAMESPACE}-regops"
    fi
    
    echo " ✓ Apply workload file for ($TAP_WORKLOAD_BACKEND_NAME) on the RUN Cluster"
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TAP_DEVELOPER_NAMESPACE}-regops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_BACKEND_NAME}-regops-deliverable.yaml > /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops-deliverable.yaml
       
echo "kubectl -n ${TAP_DEVELOPER_NAMESPACE}-regops apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops-deliverable.yaml"


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

    echo " ✓ Apply workload file for ($TAP_WORKLOAD_BACKEND_NAME) on the OPS Cluster"
    sed -e "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" \
        -e "s/namespace: newsletter/namespace: ${TAP_DEVELOPER_NAMESPACE}-regops/g" \
        $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_BACKEND_NAME}-regops-deliverable.yaml > /tmp/${TAP_WORKLOAD_BACKEND_NAME}-regops-deliverable.yaml


    echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    tanzu -n ${TAP_DEVELOPER_NAMESPACE}-gitops apps workload list 
    echo "------------------------------------------------------------------------------------------------------------------------------------------------------------------"

    echo ""
    echo "Demo Setup for '$TAP_WORKLOAD_BACKEND_NAME' and '$TAP_WORKLOAD_FRONTEND_NAME' completed"
  fi
fi

if [ "$1" == "guide" ]; then 
  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  if [ "$2" == "" ]; then
    echo "tdh guide predeploy                    ## Predeploy the Newsletter Application"
    echo "tdh guide devex                        ## Developer Experiance by developing an app in TAP on Kubernetens"
    echo "tdh guide devops                       ## Developer Experiance Multistage Demo requires (TAP Multiclaster)"
  fi

  if [ "$2" == "predeploy" ]; then
    echo "1.)  Cleanup old $TDH_DEMO_GIT_REPO GIT Repositors Local and on Github"
    echo "     => tdh clean      ## Remove GIT repos https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git and local \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    echo "     => tdh init       ## Fork $TDH_DEMO_GIT_REPO origninal GIT Repository into https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
    echo ""
    echo "2.)  Clone $TDH_DEMO_GIT_REPO from CLI"
    echo "     => git -C \$HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
    echo ""
    echo "3.)  Create Service Claim for PostgreSQL backend"
    echo "     => tdh context dev"
    echo "     => tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n $TAP_DEVELOPER_NAMESPACE"
    echo ""
    echo "     ## see status"
    echo "     => tanzu services class-claims get newsletter-db --namespace $TAP_DEVELOPER_NAMESPACE"
    echo ""
    echo "4.)  Deploy Newsletter Subscription Service"
    echo "     => tdh context dev"
    echo "     => cd \$HOME/workspace/newsletter/newsletter-subscription"
    echo "     => tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE --local-path . --update-strategy replace --yes --tail --wait"
    echo ""
    echo "     ## see logs / get status"
    echo "     => tanzu apps workload tail newsletter-subscription --namespace $TAP_DEVELOPER_NAMESPACE --timestamp --since 1h"
    echo "     => tanzu apps workload get newsletter-subscription --namespace $TAP_DEVELOPER_NAMESPACE"
    echo "     => curl https://newsletter-subscription.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/actuator 2>/dev/null | jq -r"
    echo ""
    echo "5.)  Deploy Newsletter UI Service"
    echo "     => tdh context dev"
    echo "     => cd \$HOME/workspace/newsletter/newsletter-ui"
    echo "     => tanzu apps workload apply --file config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE  --local-path . --update-strategy replace --yes --tail --wait"
    echo ""
    echo "     ## see logs / get status"
    echo "     => tanzu apps workload tail newsletter-ui --namespace $TAP_DEVELOPER_NAMESPACE --timestamp --since 1h"
    echo "     => tanzu apps workload get newsletter-ui --namespace $TAP_DEVELOPER_NAMESPACE"
    echo "     => curl https://newsletter-ui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"
    echo ""
    echo "Delete (undeploy) the Newsleter Application"
    echo "     => tdh context dev"
    echo "     => tanzu apps workload delete newsletter-subscription -n $TAP_DEVELOPER_NAMESPACE --yes"
    echo "     => tanzu apps workload delete newsletter-ui -n $TAP_DEVELOPER_NAMESPACE --yes"
  fi

  if [ "$2" == "devex" ]; then
    echo "1.)  Show Jira Ticket: JRA_411 to the audience"
    echo "     -----------------------------------------"
    echo "     https://raw.githubusercontent.com/pivotal-sadubois/newsletter/main/catalog/docs/images/jra411.jpg"
    echo ""
    echo "2.)  Clone Demo Repository"
    echo "     -----------------------------------------"
    echo "     => Clone $TDH_DEMO_GIT_REPO from VSCode"
    echo "        ▪ VSCode -> Welcome (tab) -> Clone from GIT Repository"
    echo "          (https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git)"
    echo "          into local directory: \$HOME/workspace/newsletter -- *** DO NOT YET OPEN THE PROJECT ***"
    echo "        ▪ VSCode -> Welcome (tab) -> Open Folder -> \$HOME/workspace/newsletter/newsletter-subscription"
    echo ""
    echo "     => Clone $TDH_DEMO_GIT_REPO from CLI"
    echo "     git -C \$HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
    echo ""
    echo "3.)  Open The Tanzu Application Platform (TAP)"
    echo "     -----------------------------------------"
    echo "     =>  Register the 'newsletter' app as Catalog Entity"
    echo "         ▪ TAP Gui (Home) -> Register Entity -> Repository Url"
    echo "           (https://github.com/pivotal-sadubois/newsletter/blob/main/catalog/catalog-info.yaml)"
    echo ""
    echo "4.)  Create a new Branch (JRA_411)"
    echo "     =>  Create branch with VSCode"
    echo "         ▪ VSCode -> Source Control -> Branch -> Create Branch -> JRA_411 -> <comment> -> Pulish Branch"
    echo ""
    echo "     => Create branch with CLI"
    echo "        cd \$HOME/workspace/newsletter"
    echo "        git checkout -b \"JRA_411\""
    echo ""
    echo "5.)  Create a (crossplane) Service Instance"
    echo "     ---------------------------------------"
    echo "     => View Available Service Classes"
    echo "        tanzu service class list"
    echo "        tanzu service class get postgresql-unmanaged"
    echo ""
    echo "     => Create a 'PostgreSQL' Service Claim"
    echo "        tanzu service class-claim create newsletter-db \\"
    echo "            --class postgresql-unmanaged --parameter storageGB=3 -n newsletter"
    echo "        tanzu services class-claims get newsletter-db --namespace newsletter"
    echo ""
    echo "6.)  Deploy the Newletter App"
    echo "     ------------------------"
    echo "     => Create branch with VSCode"
    echo "        ▪ VSCode -> Explorer -> Newsletter Subscription -> config/workload.yaml (right mouse button) -> "
    echo "          Tanzu Live Update"
    echo ""
    echo "     => Create branch with CLI"
    echo "        $ tanzu apps workload apply \\"
    echo "             --file \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME/config/workload.yaml \\"
    echo "             --namespace $TAP_DEVELOPER_NAMESPACE \\"
    echo "             --source-image $HARBOR/library/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "             --local-path \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "             --live-update --tail --update-strategy replace --debug --yes"
    echo ""
    #echo "        $ kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f \$HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml"
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

  echo " ✓ Generating kubeconfig for the Dev Clusterin \$HOME/.kube/config with '$TDH_SERVICE_LUSTER' and '$TAP_DEVELOPER_NAMESPACE' namespace as default context"
  echo "   Default Context will set to '$TAP_CONTEXT_DEV with '$TAP_DEVELOPER_NAMESPACE' as namespace'"
  echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
  kubectl --kubeconfig=$HOME/.kube/config config get-contexts | sed 's/^/   /g'
  echo "   ---------------------------------------------------------------------------------------------------------------------------------------------------------------"
  echo ""

if [ 1 -eq 2 ]; then 
  # --- CLEANUP FROM LAS RUN ---
  echo " ✓ Setting Gitea Demo Repository for newsletter"
  echo "   ▪ Cleanup old Repositories" 
  deleteGiteaRepo  Fortinet newsletter

  echo "   ▪ Create Orgamisation Fortinet"
  createGiteaOrg   Fortinet
  createGiteaRepo  Fortinet newsletter

  echo "   ▪ Fork the newsletter Git Repository from Github"
  giteaForkGithubRepo pivotal-sadubois newsletter Fortinet newsletter
fi

  echo " ✓ Setting up Jenkins"
  echo "   ▪ export Jobs"
  #exportJenkinsJob          newsletter build-gitea-newsletter-ui $TDHHOME/demos/$TDH_DEMO_NAME/files
  #exportJenkinsJob          newsletter build-gitea-newsletter-subscription $TDHHOME/demos/$TDH_DEMO_NAME/files
  #exportJenkinsJob          newsletter build-github-newsletter-ui $TDHHOME/demos/$TDH_DEMO_NAME/files
  #exportJenkinsJob          newsletter build-github-newsletter-subscription $TDHHOME/demos/$TDH_DEMO_NAME/files

  echo "   ▪ Verify Jenkins Plugins"
  installJenkinsPlugin   maven-plugin
  installJenkinsPlugin   pipeline-utility-steps
  installJenkinsPlugin   workflow-aggregator
  installJenkinsPlugin   junit
  #installJenkinsPlugin   envinject
  installJenkinsPlugin   pipeline-stage-view 
  installJenkinsPlugin   cloudbees-folder

  echo "   ▪ Install Jenkins Credentials"
  importJenkinsCredentials   $TDHHOME/demos/$TDH_DEMO_NAME/files/build-credentials.xml

  echo "   ▪ Install Jenkins Nodes"
  addJenkinsNode             buildhost $TDHHOME/demos/$TDH_DEMO_NAME/files/node-buildhost.xml

  echo "   ▪ Install Jenkins Folder and Jobs"
  importJenkinsFolderConfig  newsletter $TDHHOME/demos/$TDH_DEMO_NAME/files/newsletter-folder-config.xml
  importJenkinsJob           newsletter build-gitea-newsletter-ui $TDHHOME/demos/$TDH_DEMO_NAME/files
  importJenkinsJob           newsletter build-gitea-newsletter-subscription $TDHHOME/demos/$TDH_DEMO_NAME/files
  importJenkinsJob           newsletter build-github-newsletter-ui $TDHHOME/demos/$TDH_DEMO_NAME/files
  importJenkinsJob           newsletter build-github-newsletter-subscription $TDHHOME/demos/$TDH_DEMO_NAME/files

  # $JENKINS_CLI groovy = < approve-scripts.groovy

#huhu

exit

  
  # --- JENKINS ---


echo "JENKINS_API_TOKEN:$JENKINS_API_TOKEN"







exit


exit

  git -C $TMPDIR clone https://github.com/pivotal-sadubois/newsletter.git

echo "TDH_GITHUB_USER:$TDH_GITHUB_USER"

ls -la $TMPDIR

  #echo "git -C $HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"


#huhu
  

exit

echo "TDH_SERVICE_LUSTER:$TDH_SERVICE_LUSTER"

  yq ".contexts[0].context.namespace = \"$TAP_DEVELOPER_NAMESPACE\"" \
       $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/$TDH_SERVICE_LUSTER/${TDH_SERVICE_LUSTER}.kubeconfig > $HOME/.kube/config

echo gaga2
  echo " ✓ Setting up Git Demo Repository (https://github.com/$TDH_DEMO_GITHUB_USER/TDH_DEMO_GIT_REPO)"
  echo "   ▪ Verify github authorization for user '$TDH_DEMO_GITHUB_USER'" 

  gh_token=$(gh auth token) 
  if [ "$gh_token" == "" -o "$gh_token" != "$TDH_DEMO_GITHUB_TOKEN" ]; then 
    echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: Failed to login Github with the 'gh' utility, please try manually"
      echo "       => echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token"
      exit
    fi
  fi

  rep=$(gh repo list --json name | jq -r --arg key $TDH_CARTO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "" ]; then
    echo "   ▪ Create TAP Config Write Repository https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO"
    gh repo create $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO --yes >/dev/null 2>&1
  else 
    echo "   ▪ Verify TAP Config Writer Repository https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO"
  fi

  rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "" ]; then
    echo "   ▪ Fork TAP Demo repository ($TDH_DEMO_GIT_REPO) from https://github.com/pivotal-sadubois/$TDH_DEMO_GIT_REPO.git"
    echo "Y" | gh repo fork https://github.com/pivotal-sadubois/$TDH_DEMO_GIT_REPO.git
  else
    echo "   ▪ Verify TAP Demo Repository https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
  fi

  # --- CREATE GITOPS CARTOGRAPHER REPO ---
  rep=$(gh repo list --json name | jq -r --arg key $TDH_CARTO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" != "$TDH_CARTO_GIT_REPO" ]; then
    echo " ✓ Create repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO"
    gh repo create $TDH_CARTO_GIT_REPO --public >/dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to create github repository $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO, please try manually"
      echo "       => gh repo create $TDH_CARTO_GIT_REPO --public"
      exit 1
    fi
  fi

  # --- DEV CLUSTER ---
  echo " ✓ Verify Kubernetes Cluster Accessability ($TAP_CLUSTER_DEV)"
  kubectl config use-context $TAP_CONTEXT_DEV > /dev/null
  kubectl get ns > /tmp/error.log 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    cat /tmp/error.log
    echo "ERROR: Failed to access the kubernetes cluster, please try manually"
    echo "       => kubectl get ns"
    exit
  fi

  nam=$(kubectl get ns -o json | jq -r --arg key $TAP_DEVELOPER_NAMESPACE '.items[].metadata | select(.name == $key).name')
  if [ "$nam" == "" ]; then 
    echo "   ▪ Creating Developer Namespace for '$TAP_DEVELOPER_NAMESPACE' on $TAP_CLUSTER_DEV"
    createNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

    echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
    kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1

    echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
    kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1

    echo "   ▪ Creating Docker Pull Secret in 'default' service account"
    dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE} docker-credentials

    echo "   ▪ Create Github SSH Access Secret (github-http-secret) in namespace ${TAP_DEVELOPER_NAMESPACE}"
    configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}
  else
    echo "   ▪ Verify Developer Namespace for '$TAP_DEVELOPER_NAMESPACE'"
  fi

  echo "   ▪ Adding Scan Policy (newsletter-scan-policy) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
  GITURL="https://raw.githubusercontent.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO/main/$TAP_WORKLOAD_BACKEND_NAME/config/newsletter-scan-policy.yaml"
  kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: failed to add scan policy, please try manually"
    echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
    echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL"
    exit
  fi

  echo "   ▪ Adding Pipline ($pipeline-notest) to Developer Namespace ($TAP_DEVELOPER_NAMESPACE)"
  GITURL="https://raw.githubusercontent.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO/main/$TAP_WORKLOAD_BACKEND_NAME/config/pipeline-notest.yaml"
  kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: failed to add pipeline pipeline-notest, please try manually"
    echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
    echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f $GITURL"
    exit
  fi

  # --- MULTI CLUSTER ---
  if [ "$TDH_DEPLOYMENT_TYPE"  == "tap-multicluster" ]; then
    ########################################################################################################################
    ######################################### OPS CLUSTER ##################################################################
    ########################################################################################################################
    echo " ✓ Verify Kubernetes Cluster Accessability ($TAP_CLUSTER_OPS)"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
    kubectl get ns > /tmp/error.log 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      cat /tmp/error.log
      echo "ERROR: Failed to access the kubernetes cluster, please try manually"
      echo "       => kubectl get ns"
      exit
    fi

    createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-regops
    createTAPNamespace $TAP_CONTEXT_OPS ${TAP_DEVELOPER_NAMESPACE}-gitops

#    nam=$(kubectl get ns -o json | jq -r --arg key ${TAP_DEVELOPER_NAMESPACE}-regops '.items[].metadata | select(.name == $key).name')
#    if [ "$nam" == "" ]; then 
#      kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
#
#      echo "   ▪ Creating Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-gitops'"
#      createNamespace ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
#
#      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-gitops apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
#      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-gitops pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
#
#      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
#      dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE}-gitops docker-credentials
#      configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}-gitops
#
#
#      echo "   ▪ Creating Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-regops'"
#      createNamespace ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
#
#      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-regops apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
#      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-regops pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
#
#      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
#      dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE}-regops docker-credentials
#      configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}-regops
#    else
#      echo "   ▪ Verify Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-gitops'"
#      echo "   ▪ Verify Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-regops'"
#    fi

    ########################################################################################################################
    ######################################### RUN CLUSTER ##################################################################
    ########################################################################################################################
    echo " ✓ Verify Kubernetes Cluster Accessability ($TAP_CLUSTER_RUN)"
    createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-regops
    createTAPNamespace $TAP_CONTEXT_RUN ${TAP_DEVELOPER_NAMESPACE}-gitops



#    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null
#    nam=$(kubectl get ns -o json | jq -r --arg key $TAP_DEVELOPER_NAMESPACE '.items[].metadata | select(.name == $key).name')
#    if [ "$nam" == "" ]; then
#      kubectl config use-context $TAP_CONTEXT_RUN > /dev/null
#
#      echo "   ▪ Creating Run Namespace for '${TAP_DEVELOPER_NAMESPACE}-gitops'"
#      createNamespace ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
#
#      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-gitops apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
#      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-gitops pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
#
#      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
#      dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE}-gitops docker-credentials
#      configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}-gitops
#
#
#      echo "   ▪ Creating Run Namespace for '${TAP_DEVELOPER_NAMESPACE}-regops'"
#      createNamespace ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
#
#      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-regops apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
#      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
#      kubectl label namespaces ${TAP_DEVELOPER_NAMESPACE}-regops pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
#
#      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
#      dockerPullSecretV2  ${TAP_DEVELOPER_NAMESPACE}-regops docker-credentials
#      configWriterSecrets ${TAP_DEVELOPER_NAMESPACE}-regops
#    else
#      echo "   ▪ Verify Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-gitops'"
#      echo "   ▪ Verify Build Namespace for '${TAP_DEVELOPER_NAMESPACE}-regops'"
#    fi

    if [ "$TDH_DEMO_GITHUB_USER" == "" -o "$TDH_DEMO_GITHUB_TOKEN" == "" ]; then 
      echo "Please set the TDH_DEMO_GITHUB_USER and TDH_DEMO_GITHUB_TOKEN variable in your \$HOME/.tanzu-demo-hub.cfg file"
      exit
    fi
  fi

  echo " ✓ Update VSCode config in (\$HOME/Library/Application Support/Code/User/settings.json)"
  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"
  TAPGUI="https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  sed -i '' -e 's/$/~1~/g' -e 's/,~1~/~1~,/g' \
            -e "/\"tanzu.namespace\": /s/^\(.*: \).*~1~/\1\"$TAP_DEVELOPER_NAMESPACE\"~1~/g" \
            -e "/\"tanzu.sourceImage\": /s+^\(.*: \).*~1~+\1\"$HARBOR/library/$TAP_WORKLOAD_BACKEND_NAME\"~1~+g" \
            -e "/\"tanzu-app-accelerator.tapGuiUrl\": /s+^\(.*: \).*~1~+\1\"$TAPGUI\"~1~+g" \
            -e "/\"tanzu-app-accelerator.tanzuApplicationPlatformGuiUrl\": /s+^\(.*: \).*~1~+\1\"$TAPGUI\"~1~+g" \
            -e 's/~1~//g' $HOME/Library/Application\ Support/Code/User/settings.json

  #harbor_url=$(kubectl get cm tanzu-demo-hub -o json | jq -r '.data.TDH_INGRESS_CONTOUR_LB_DOMAIN' | sed 's/apps/harbor/g')
  harbor_url=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.key)
  harbor_usr=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.value.username)
  harbor_pss=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.value.password)

  echo " ✓ login into harbor registry $harbor_url https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
  docker login $harbor_url -u $harbor_usr -p $harbor_pss > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: Failed to login local docker registry $harbor_url, please try manually"
    echo "       => docker login $harbor_url -u $harbor_usr -p $harbor_pss"
    exit
  fi

  # --- SETUP DEMO LOCK FILES ---
  [ ! -d $HOME/.tdh ] && mkdir -p $HOME/.tdh
  echo "$TDH_DEMO_NAME" > $HOME/.tdh/tdh_demo_name.cfg 
  echo "$TDH_DEMO_CONFIG" > $HOME/.tdh/tdh_demo_config.cfg 

  echo ""
  echo "Demo Initialization successfuly completed"
fi

if [ "$1" == "clean" ]; then 
  # --- DELETE TAP DEMP REPO ---
  rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "$TDH_DEMO_GIT_REPO" ]; then
    echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
    gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes >/dev/null 2>&1
  fi

  # --- DELETE GITOPS CARTOGRAPHER REPO ---
  rep=$(gh repo list --json name | jq -r --arg key $TDH_CARTO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "$TDH_CARTO_GIT_REPO" ]; then
    echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO"
    gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_CARTO_GIT_REPO --yes >/dev/null 2>&1
  fi
  
  if [ -d $HOME/workspace/$TDH_DEMO_GIT_REPO ]; then 
    echo " ✓ Deleted local git repository \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    rm -rf $HOME/workspace/$TDH_DEMO_GIT_REPO
  fi

  echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_DEV)"
  kubectl config use-context $TAP_CONTEXT_DEV > /dev/null

  for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null | jq -r '.items[].metadata.name'); do
    echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then                      
      echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
      exit
    fi
  done

  for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload -o json 2>/dev/null | jq -r '.items[].metadata.name'); do
    echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
     kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$? 
    if [ $ret -ne 0 ]; then        
      echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
      echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
      exit
    fi
  done

  kubectl delete ns $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

  if [ "$TDH_DEPLOYMENT_TYPE"  == "tap-multicluster" ]; then
    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_OPS)"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null

    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
      echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
      kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then        
        echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
        exit
      fi
    done 

    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get workload -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
      echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
       kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then  
        echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
        exit
      fi
    done

    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1

    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE' on Cluster ($TAP_CLUSTER_RUN)"
    kubectl config use-context $TAP_CONTEXT_RUN > /dev/null

    for n in $(kubectl -n $TAP_DEVELOPER_NAMESPACE get classclaims -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
      echo "   ▪ Deleted Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
      kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: Failed to delete Service Class ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete classclaims $n"
        exit
      fi
    done

    for n in $(kubectl -n $n get workload -o json 2>/dev/null| jq -r '.items[].metadata.name'); do
      echo "   ▪ Deleted App Workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
       kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n > /dev/null 2>&1; ret=$?
      if [ $ret -ne 0 ]; then
        echo "ERROR: Failed to delete workload ($n) in namespace $TAP_DEVELOPER_NAMESPACE"
        echo "       => kubectl -n $TAP_DEVELOPER_NAMESPACE delete workload $n"
        exit
      fi
    done

    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-gitops > /dev/null 2>&1
    kubectl delete ns ${TAP_DEVELOPER_NAMESPACE}-regops > /dev/null 2>&1
  fi

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

tanzu apps workload delete newsletter-subscription -n newsletter --yes
tanzu apps workload apply --file $HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml --namespace newsletter \
     --source-image harbor.apps.tapmc.tanzudemohub.com/library/newsletter-subscription \
     --local-path $HOME/workspace/newsletter/newsletter-subscription \
     --live-update --tail --update-strategy replace --debug --yes

tanzu apps workload delete newsletter-ui -n newsletter-ui --yes
tanzu apps workload apply --file $HOME/workspace/newsletter/newsletter-ui/config/workload.yaml --namespace newsletter-ui \
     --source-image harbor.apps.tapmc.tanzudemohub.com/library/newsletter-ui \
     --local-path $HOME/workspace/newsletter/newsletter-ui \
     --live-update --tail --update-strategy replace --debug --yes


tanzu apps workload delete newsletter-ui -n newsletter --yes
tanzu apps workload delete angular-frontend -n newsletter --yes
tanzu apps workload apply --file config/workload.yaml --namespace newsletter-ui --local-path .  --yes --tail
tanzu apps workload apply --file config/workload.yaml --namespace newsletter --local-path .  --yes --tail
tanzu apps workload apply --file config/workload.yaml --namespace newsletter --local-path .  --yes --tail

tanzu apps workload list -n newsletter
    myArray=("Elvis:Presley" "Paul:McCartney" "Alice:Cooper" "Tina:Turner" "Liam:Gallagher" "Nick:Cave" "Keith:Richards" "David:Byrne" "Gary:Puckett" "Little:Richard" "Axl:Rose" "David:Bowie" "Bob:Dylan" "Bruce:Springsteen" "Mike:Jagger")

  TMPFILE=/tmp/1.json; rm -f $TMPFILE
  echo "["                       > $TMPFILE

  i=1
  for n in ${myArray[@]}; do
    fn=$(echo $n | awk -F: '{ print $1 }')
    ln=$(echo $n | awk -F: '{ print $2 }')
    em="${fn}.${ln}@example.com"

    echo " {"                          >> $TMPFILE
    echo "  \"emailId\": \"$em\","     >> $TMPFILE
    echo "  \"firstName\": \"$fn\","   >> $TMPFILE
    echo "  \"lastName\": \"$ln\""     >> $TMPFILE

    [ $i -ne ${#myArray[@]} ] && str="," || str=""

    echo " }$str"                      >> $TMPFILE
    let i=i+1
  done

  echo "]"                             >> $TMPFILE

    echo "curl -X 'POST' 'https://$TAP_WORKLOAD_BACKEND_NAME.ops.${DNS_SUBDOMAIN}.${DNS_DOMAIN}/api/v1/subscriptions' -H 'accept: application/json' -H 'Content-Type: application/json' -d \"@$TMPFILE\""

