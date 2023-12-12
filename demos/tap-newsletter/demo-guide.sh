#!/bin/bash

TAP_DEVELOPER_NAMESPACE=newsletter

if [ "$1" == "" ]; then 
  echo "tdh init                               ## Initialize Newsletter Demo (Fork Git Repo)"
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

if [ "$1" == "init" ]; then 
  echo " ✓ Generating kubeconfig in \$HOME/.kube/config with '$TDH_SERVICE_LUSTER' and '$TAP_DEVELOPER_NAMESPACE' namespace as default context"
  echo "   Default Context will set to '$TAP_CONTEXT_DEV with '$TAP_DEVELOPER_NAMESPACE' as namespace'"
  echo "   ------------------------------------------------------------------------------------------------------------------------------------------------------------"
  kubectl --kubeconfig=$HOME/.kube/config config get-contexts | sed 's/^/   /g'
  echo "   ------------------------------------------------------------------------------------------------------------------------------------------------------------"

  yq ".contexts[0].context.namespace = \"$TAP_DEVELOPER_NAMESPACE\"" \
       $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/$TDH_SERVICE_LUSTER/${TDH_SERVICE_LUSTER}.kubeconfig > $HOME/.kube/config

  # --- DEV CLUSTER ---
  echo " ✓ Creating Developer Namespace for '$TAP_DEVELOPER_NAMESPACE' on $TAP_CLUSTER_DEV"
  kubectl config use-context $TAP_CONTEXT_DEV > /dev/null
  createNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
  dockerPullSecret $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1                          
  kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
  kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
  
  # --- OPS CLUSTER ---
  echo " ✓ Creating Developer Namespace for '$TAP_DEVELOPER_NAMESPACE' on $TAP_CLUSTER_OPS"
  kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
  createNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
  dockerPullSecret $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1                          
  kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
  kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1

  SSHDIR=$HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/git-ssh
  if [ ! -d $SSHDIR ]; then 
    mkdir -p $SSHDIR

    cd $SSHDIR && ssh-keygen -R github.com > /dev/null 2>&1
    cd $SSHDIR && ssh-keygen -t ecdsa -b 521 -C "" -f "identity" -N "" > /dev/null 2>&1
    cd $SSHDIR && ssh-keyscan github.com > ./known_hosts 2>/dev/null
    gh ssh-key add -t "tap" $SSHDIR/identity.pub > /dev/null 2>&1; ret=$?
  fi

  echo " ✓ Creating 'git-ssh' secret in the 'tap-namespace-provisioning' namespace"
  kubectl delete secret git-ssh -n tap-namespace-provisioning > /dev/null 2>&1
  kubectl create secret generic git-ssh -n tap-namespace-provisioning \
    --from-file=$SSHDIR/identity \
    --from-file=$SSHDIR/identity.pub \
    --from-file=$SSHDIR/known_hosts > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    echo "ERROR: failed to create secret git-ssh, please try manually"
    echo "kubectl create secret generic git-ssh -n tap-namespace-provisioning \\"
    echo "  --from-file=$SSHDIR/identity \\"
    echo "  --from-file=$SSHDIR/identity.pub \\"
    echo "  --from-file=$SSHDIR/known_hosts"
    exit
  fi

  SSH_CONFIG=$SSHDIR/github-ssh-secret.yaml
  echo "apiVersion: v1"                                                                  >  $SSH_CONFIG
  echo "kind: Secret"                                                                    >> $SSH_CONFIG
  echo "metadata:"                                                                       >> $SSH_CONFIG
  echo "  name: github-ssh-secret"                                                       >> $SSH_CONFIG
  echo "  annotations: {tekton.dev/git-0: github.com}"                                   >> $SSH_CONFIG
  echo "type: kubernetes.io/ssh-auth"                                                    >> $SSH_CONFIG
  echo "stringData:"                                                                     >> $SSH_CONFIG
  echo "  ssh-privatekey: |"                                                             >> $SSH_CONFIG
  cat $SSHDIR/identity | sed 's/^/      /g'                                              >> $SSH_CONFIG
  echo "  identity: |"                                                                   >> $SSH_CONFIG
  cat $SSHDIR/identity | sed 's/^/      /g'                                              >> $SSH_CONFIG
  echo "  identity.pub: $(base64 -i $SSHDIR/identity.pub)"                               >> $SSH_CONFIG
  echo "  known_hosts: $(base64 -i $SSHDIR/known_hosts)"                                 >> $SSH_CONFIG

  echo " ✓ Create Github SSH Access Secret"
  kubectl delete secret github-ssh-secret -n tap-namespace-provisioning > /dev/null 2>&1
  kubectl apply -f $SSH_CONFIG -n tap-namespace-provisioning > /dev/null 2>&1

  SSH_CONFIG=$SSHDIR/github-http-secret.yaml
  echo "apiVersion: v1"                                                                  >  $SSH_CONFIG
  echo "kind: Secret"                                                                    >> $SSH_CONFIG
  echo "metadata:"                                                                       >> $SSH_CONFIG
  echo "  name: github-http-secret"                                                      >> $SSH_CONFIG
  echo "  annotations:"                                                                  >> $SSH_CONFIG
  echo "    tekton.dev/git-0: https://github.com/"                                       >> $SSH_CONFIG
  echo "    tekton.dev/git-1: http://github.com/"                                        >> $SSH_CONFIG
  echo "type: kubernetes.io/basic-auth"                                                  >> $SSH_CONFIG
  echo "stringData:"                                                                     >> $SSH_CONFIG
  echo "  username: $TDH_DEMO_GITHUB_USER"                                               >> $SSH_CONFIG
  echo "  password: $TDH_DEMO_GITHUB_TOKEN"                                              >> $SSH_CONFIG

  echo " ✓ Create Github SSH Access Secret"
  kubectl delete secret github-http-secret -n tap-namespace-provisioning > /dev/null 2>&1
  kubectl apply -f $SSH_CONFIG -n tap-namespace-provisioning > /dev/null 2>&1


echo $SSH_CONFIG



exit
  cp $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/kubeconfig_${TDH_DEPLOYMENT_NAME}.yaml $HOME/.kube/config

ls -la $$HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/

exit

  echo " ✓ Setting up Kubernetes Context to the TAP Dev Cluster: $TAP_CONTEXT_DEV"
  kubectl config use-context $TAP_CONTEXT_DEV > /tmp/error.log 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    cat /tmp/error.log
    echo "ERROR: Failed to set kubernetes context to the TAP Dev Cluster, please try manually"
    echo "       => kubectl config use-context $TAP_CONTEXT_DEV"
    exit
  fi

  echo " ✓ Verify Kubernetes Cluster Accessability"
  kubectl get ns > /tmp/error.log 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    cat /tmp/error.log
    echo "ERROR: Failed to access the kubernetes cluster, please try manually"
    echo "       => kubectl get ns"
    exit
  fi

  if [ "$TDH_DEMO_GITHUB_USER" == "" -o "$TDH_DEMO_GITHUB_TOKEN" == "" ]; then 
    echo "Please set the TDH_DEMO_GITHUB_USER and TDH_DEMO_GITHUB_TOKEN variable in your \$HOME/.tanzu-demo-hub.cfg file"
    exit
  fi

  ns=$(kubectl get ns -o json | jq -r '.items[].metadata | select(.name == "newsletter").name')
  if [ "$ns" != "newsletter" ]; then
    echo "ERROR: The developer namespace 'newsletter' does not exist yet, please do the following stepts:"
    echo "       => tools/tdh-tools-tkg-2.2.1.sh"
    echo "          tdh-tools:/$ cd \$HOME/workspacea/tanzu-demo-hub/scripts"
    echo "          tdh-tools:/$ ./tap-create-developer-namespace.sh newsletter"

    exit
  fi

  echo " ✓ Verify github authorization"
  gh auth token > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then 
    echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then 
      echo "ERROR: Failed to login Github with the 'gh' utility, please try manually"
      echo "       => echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token"
      exit
    fi
  fi

  DNS_DOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_domain')
  DNS_SUBDOMAIN=$(yq -o json $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml | jq -r '.tdh_environment.network.dns.dns_subdomain')
  HARBOR="harbor.apps.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"
  TAPGUI="https://tap-gui.dev.${DNS_SUBDOMAIN}.${DNS_DOMAIN}"

  echo " ✓ Update VSCode config in (\$HOME/Library/Application Support/Code/User/settings.json)"
  sed -i '' "s/\"tanzu.namespace\": .*$/\"tanzu.namespace\": \"$TAP_DEVELOPER_NAMESPACE\" /" $HOME/Library/Application\ Support/Code/User/settings.json
  sed -i '' "s/\"tanzu.sourceImage\": .*$/\"tanzu.sourceImage\": \"$HARBOR\" /" $HOME/Library/Application\ Support/Code/User/settings.json
  sed -i '' "s+\"tanzu-app-accelerator.tapGuiUrl\": .*$+\"tanzu-app-accelerator.tapGuiUrl\": \"$TAPGUI\" +" $HOME/Library/Application\ Support/Code/User/settings.json


# harbor.apps.tap.tanzudemohub.com/library/newsletter

echo "TAP_CLUSTER_DEV:$TAP_CLUSTER_DEV"
echo "$HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/config.yml"

exit


echo end; exit

  echo "✓ Fork repository https://github.com/$TDH_DEMO_GITHUB_USER/newsletter"
  echo "Y" | gh repo fork https://github.com/pivotal-sadubois/newsletter.git 

  #harbor_url=$(kubectl get cm tanzu-demo-hub -o json | jq -r '.data.TDH_INGRESS_CONTOUR_LB_DOMAIN' | sed 's/apps/harbor/g')
  harbor_url=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.key)
  harbor_usr=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.value.username)
  harbor_pss=$(kubectl get secrets tap-registry -n tap-install -o json | jq -r '.data.".dockerconfigjson"' | base64 -d | jq -r '.auths | to_entries[]'.value.password)

  echo "✓ login into harbor registry $harbor_url https://github.com/$TDH_DEMO_GITHUB_USER/newsletter"
  docker login $harbor_url -u $harbor_usr -p $harbor_pss > /dev/null 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    echo "ERROR: Failed to login local docker registry $harbor_url, please try manually"
    echo "       => docker login $harbor_url -u $harbor_usr -p $harbor_pss"
    exit
  fi

fi

if [ "$1" == "k" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "kubectl get events -n newsletter --sort-by='lastTimestamp'"
fi

if [ "$1" == "clean" ]; then 
  gh repo delete $TDH_DEMO_GITHUB_USER/newsletter --yes 2>/dev/null
  #[ -d $HOME/workspace/newsletter ] && rm -rf $HOME/workspace/newsletter
  tanzu services class-claims delete newsletter-db --namespace newsletter -y 2>/dev/null
fi

if [ "$1" == "git" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "git -C $HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
  echo "https://github.com/$TDH_DEMO_GITHUB_USER/newsletter/blob/main/catalog/catalog-info.yaml"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "sc1" ]; then 
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

