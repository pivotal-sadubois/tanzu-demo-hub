#!/bin/bash
# ############################################################################################
# File: ........: demo-guide.sh
# Language .....: bash 
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Newsletter Demo Guide
# ############################################################################################

#curl -X 'POST' \
#  'https://newsletter-subscription.dev.tapmc.tanzudemohub.com/api/v1/subscriptions' \
#  -H 'accept: application/json' \
#  -H 'Content-Type: application/json' \
#  -d '[
#  {
#    "emailId": "john@example.com",
#    "firstName": "John",
#    "lastName": "Fogerty"
#  },
#  {
#    "emailId": "frank@example.com",
#    "firstName": "Frank",
#    "lastName": "Zappa"
#  },
#  {
#    "emailId": "bob@example.com",
#    "firstName": "Bob",
#    "lastName": "Seger"
#  }
#]'

TAP_DEVELOPER_NAMESPACE=newsletter
TAP_WORKLOAD_FRONTEND_NAME=newsletter-ui
TAP_WORKLOAD_FRONTEND_FILE=${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml
TAP_WORKLOAD_BACKEND_NAME=newsletter-subscription
TAP_WORKLOAD_BACKEND_FILE=${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml
TDH_DEMO_GIT_REPO=newsletter

#tanzu accelerator list --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator get tanzu-java-web-app --server-url http://tap-gui.dev.tapmc.v2steve.net
#tanzu accelerator generate  tanzu-java-web-app --options '{"projecName":"tjwa"}' --server-url https://accelerator.dev.tapmc.v2steve.net

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

# https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow
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
    echo "     => https://raw.githubusercontent.com/pivotal-sadubois/newsletter/main/catalog/docs/images/jra411.jpg"
    echo ""
    echo "2.)  Clone Demo Repository"
    echo "     => Clone $TDH_DEMO_GIT_REPO from VSCode"
    echo "        ▪ VSCode -> Welcome (tab) -> Clone from GIT Repository (https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git)"
    echo "          into local directory: \$HOME/workspace/newsletter -- *** DO NOT YET OPEN THE PROJECT ***"
    echo "        ▪ VSCode -> Welcome (tab) -> Open Folder -> \$HOME/workspace/newsletter/newsletter-subscription"
    echo ""
    echo "     => Clone $TDH_DEMO_GIT_REPO from CLI"
    echo "        $ git -C \$HOME/workspace clone https://github.com/$TDH_DEMO_GITHUB_USER/newsletter.git"
    echo ""
    echo "3.)  Open The Tanzu Application Platform (TAP)"
    echo "     => Register the 'newsletter' app as Catalog Entity"
    echo "        ▪ TAP Gui (Home) -> Register Entity -> Repository Url: https://github.com/pivotal-sadubois/newsletter/blob/main/catalog/catalog-info.yaml"
    echo ""
    echo "4.)  Create a new Branch (JRA_411)"
    echo "     => Create branch with VSCode"
    echo "        ▪ VSCode -> Source Control -> Branch -> Create Branch -> JRA_411 -> <comment> -> Pulish Branch"
    echo ""
    echo "     => Create branch with CLI"
    echo "        $ cd \$HOME/workspace/newsletter"
    echo "        $ git checkout -b \"JRA_411\""
    echo ""
    echo "5.)  Create a (crossplane) Service Instance"
    echo "     => View Available Service Classes"
    echo "        $ tanzu service class list"
    echo "        $ tanzu service class get postgresql-unmanaged"
    echo ""
    echo "     => Create a 'PostgreSQL' Service Claim"
    echo "        $ tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n newsletter"
    echo "        $ tanzu services class-claims get newsletter-db --namespace newsletter"
    echo ""
    echo "6.)  Deploy App"
    echo "     => Create branch with VSCode"
    echo "        ▪ VSCode -> Explorer -> Newsletter Subscription -> config/workload.yaml (right mouse button) -> Tanzu Live Update"
    echo ""
    echo "     => Create branch with CLI"
    echo "        $ tanzu apps workload apply --file \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME/config/workload.yaml --namespace $TAP_DEVELOPER_NAMESPACE \\"
    echo "             --source-image $HARBOR/library/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "             --local-path \$HOME/workspace/$TDH_DEMO_GIT_REPO/$TAP_WORKLOAD_BACKEND_NAME \\"
    echo "             --live-update --tail --update-strategy replace --debug --yes"
    echo ""
    #echo "        $ kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f \$HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml"
  fi
fi

if [ "$1" == "init" ]; then 
  echo " ✓ Generating kubeconfig in \$HOME/.kube/config with '$TDH_SERVICE_LUSTER' and '$TAP_DEVELOPER_NAMESPACE' namespace as default context"
  echo "   Default Context will set to '$TAP_CONTEXT_DEV with '$TAP_DEVELOPER_NAMESPACE' as namespace'"
  echo "   ------------------------------------------------------------------------------------------------------------------------------------------------------------"
  kubectl --kubeconfig=$HOME/.kube/config config get-contexts | sed 's/^/   /g'
  echo "   ------------------------------------------------------------------------------------------------------------------------------------------------------------"

  yq ".contexts[0].context.namespace = \"$TAP_DEVELOPER_NAMESPACE\"" \
       $HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/$TDH_SERVICE_LUSTER/${TDH_SERVICE_LUSTER}.kubeconfig > $HOME/.kube/config

  echo " ✓ Setting up Git Demo Repository (https://github.com/$TDH_DEMO_GITHUB_USER/TDH_DEMO_GIT_REPO)"
  echo "   ▪ Verify github authorization for user '$TDH_DEMO_GITHUB_USER'" 
  echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token > /dev/null 2>&1; ret=$?
  gh auth logout --user $TDH_DEMO_GITHUB_USER
  if [ $ret -ne 0 ]; then
    if [ $ret -ne 0 ]; then
      echo "ERROR: Failed to login Github with the 'gh' utility, please try manually"
      echo "       => echo "$TDH_DEMO_GITHUB_TOKEN" | gh auth login -p https --with-token"
      echo "       => gh auth logout --user $TDH_DEMO_GITHUB_USER"
      exit 
    fi
  fi

echo debug_end
exit

  rep=$(gh repo list --json name | jq -r --arg key cartographer '.[] | select(.name == $key).name')
  if [ "$rep" == "" ]; then
    echo "   ▪ Create TAP Config Write Repository https://github.com/$TDH_DEMO_GITHUB_USER/cartographer"
    gh repo create $TDH_DEMO_GITHUB_USER/cartographer --yes >/dev/null 2>&1
  else 
    echo "   ▪ Verify TAP Config Writer Repository https://github.com/$TDH_DEMO_GITHUB_USER/cartographer"
  fi

  rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "" ]; then
    echo "   ▪ Fork TAP Demo repository ($TDH_DEMO_GIT_REPO) from https://github.com/pivotal-sadubois/$TDH_DEMO_GIT_REPO.git"
    echo "Y" | gh repo fork https://github.com/pivotal-sadubois/$TDH_DEMO_GIT_REPO.git
  else
    echo "   ▪ Verify TAP Demo Repository https://github.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
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
    echo "   ▪ Creating Docker Pull Secret in 'default' service account"
    dockerPullSecret $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1                          
    echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
    kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
    echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
    kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
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

# ----
    SSHDIR=$HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/git-ssh
    if [ ! -d $SSHDIR ]; then
      mkdir -p $SSHDIR

      cd $SSHDIR && ssh-keygen -R github.com > /dev/null 2>&1
      cd $SSHDIR && ssh-keygen -t ecdsa -b 521 -C "" -f "identity" -N "" > /dev/null 2>&1
      cd $SSHDIR && ssh-keyscan github.com > ./known_hosts 2>/dev/null
      gh ssh-key add -t "tap" $SSHDIR/identity.pub > /dev/null 2>&1; ret=$?
    fi

    # THIS SHIT DOES NOT WORK !!!!!!
    echo "   ▪ Create Github SSH Access Secret (git-ssh) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret git-ssh -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl create secret generic git-ssh -n $TAP_DEVELOPER_NAMESPACE \
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

    # THIS SHIT WORKS !!!!!!
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

    echo "   ▪ Create Github SSH Access Secret (github-ssh-secret) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret github-ssh-secret -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl apply -f $SSH_CONFIG -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1


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

    echo "   ▪ Create Github SSH Access Secret (github-http-secret) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret github-http-secret -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl apply -f $SSH_CONFIG -n $TAP_DEVELOPER_NAMESPAC$TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

# ----

  # --- OPS CLUSTER ---
  if [ "$TDH_DEPLOYMENT_TYPE"  == "tap-multicluster" ]; then
    echo " ✓ Verify Kubernetes Cluster Accessability ($TAP_CLUSTER_OPS)"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
    kubectl get ns > /tmp/error.log 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      cat /tmp/error.log
      echo "ERROR: Failed to access the kubernetes cluster, please try manually"
      echo "       => kubectl get ns"
      exit
    fi

    nam=$(kubectl get ns -o json | jq -r --arg key $TAP_DEVELOPER_NAMESPACE '.items[].metadata | select(.name == $key).name')
    if [ "$nam" == "" ]; then 
      echo "   ▪ Creating Developer Namespace for '$TAP_DEVELOPER_NAMESPACE'"
      kubectl config use-context $TAP_CONTEXT_OPS > /dev/null
      createNamespace $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
      echo "   ▪ Creating Docker Pull Secret in 'default' service account"
      dockerPullSecret $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1                          
      echo "   ▪ Add Label for TAP Nameservice Provisoner 'apps.tanzu.vmware.com/tap-ns=\"\""
      kubectl label namespaces $TAP_DEVELOPER_NAMESPACE apps.tanzu.vmware.com/tap-ns="" > /dev/null 2>&1
      echo "   ▪ Add Label for Pod Security (Admission Controller) 'pod-security.kubernetes.io/enforce=baseline'"
      kubectl label namespaces $TAP_DEVELOPER_NAMESPACE pod-security.kubernetes.io/enforce=baseline > /dev/null 2>&1
    else
      echo "   ▪ Verify Developer Namespace for '$TAP_DEVELOPER_NAMESPACE'"
    fi

    SSHDIR=$HOME/.tanzu-demo-hub/deployments/$TDH_DEMO_CONFIG/git-ssh
    if [ ! -d $SSHDIR ]; then 
      mkdir -p $SSHDIR
  
      cd $SSHDIR && ssh-keygen -R github.com > /dev/null 2>&1
      cd $SSHDIR && ssh-keygen -t ecdsa -b 521 -C "" -f "identity" -N "" > /dev/null 2>&1
      cd $SSHDIR && ssh-keyscan github.com > ./known_hosts 2>/dev/null
      gh ssh-key add -t "tap" $SSHDIR/identity.pub > /dev/null 2>&1; ret=$?
    fi

    # THIS SHIT DOES NOT WORK !!!!!!
    echo "   ▪ Create Github SSH Access Secret (git-ssh) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret git-ssh -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl create secret generic git-ssh -n $TAP_DEVELOPER_NAMESPACE \
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

    # THIS SHIT WORKS !!!!!!
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

    echo "   ▪ Create Github SSH Access Secret (github-ssh-secret) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret github-ssh-secret -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl apply -f $SSH_CONFIG -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1


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

    echo "   ▪ Create Github SSH Access Secret (github-http-secret) in namespace $TAP_DEVELOPER_NAMESPACE"
    kubectl delete secret github-http-secret -n $TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1
    kubectl apply -f $SSH_CONFIG -n $TAP_DEVELOPER_NAMESPAC$TAP_DEVELOPER_NAMESPACE > /dev/null 2>&1

    if [ "$TDH_DEMO_GITHUB_USER" == "" -o "$TDH_DEMO_GITHUB_TOKEN" == "" ]; then 
      echo "Please set the TDH_DEMO_GITHUB_USER and TDH_DEMO_GITHUB_TOKEN variable in your \$HOME/.tanzu-demo-hub.cfg file"
      exit
    fi

    ns=$(kubectl get ns -o json | jq -r --arg key "$TAP_DEVELOPER_NAMESPACE" '.items[].metadata | select(.name == $key).name')
    if [ "$ns" != "$TAP_DEVELOPER_NAMESPACE" ]; then
      echo "ERROR: The developer namespace '$TAP_DEVELOPER_NAMESPACE' does not exist yet, please do the following stepts:"
      echo "       => tools/tdh-tools-tkg-2.2.1.sh"
      echo "          tdh-tools:/$ cd \$HOME/workspacea/tanzu-demo-hub/scripts"
      echo "          tdh-tools:/$ ./tap-create-developer-namespace.sh $TAP_DEVELOPER_NAMESPACE"

      exit
    fi

    echo " ✓ Apply workload file for ($TAP_WORKLOAD_BACKEND_NAME) on the OPS Cluster"
    kubectl config use-context $TAP_CONTEXT_OPS > /dev/null

    sed "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml > /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml

    kubectl -n $TAP_DEVELOPER_NAMESPACE delete -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml >/dev/null 2>&1
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f /tmp/${TAP_WORKLOAD_BACKEND_NAME}-gitops.yaml --wait  >/dev/null 2>&1
    echo "  => tanzu apps workload get $TAP_WORKLOAD_BACKEND_NAME -n $TAP_DEVELOPER_NAMESPACE"

tanzu apps workload list -n newsletter

    echo " ✓ Apply workload file for ($TAP_WORKLOAD_FRONTEND_NAME) on the OPS Cluster"
    sed "s/GIT_USER/$TDH_DEMO_GITHUB_USER/g" $TDHHOME/demos/$TDH_DEMO_NAME/workload/template_${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml > /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml

    kubectl -n $TAP_DEVELOPER_NAMESPACE delete -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml >/dev/null 2>&1
    kubectl -n $TAP_DEVELOPER_NAMESPACE apply -f /tmp/${TAP_WORKLOAD_FRONTEND_NAME}-gitops.yaml --wait  >/dev/null 2>&1
    echo "  => tanzu apps workload get $TAP_WORKLOAD_FRONTEND_NAME -n $TAP_DEVELOPER_NAMESPACE"

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

  echo ""
  echo "Demo Initialization successfuly completed"
fi

if [ "$1" == "clean" ]; then 
  rep=$(gh repo list --json name | jq -r --arg key $TDH_DEMO_GIT_REPO '.[] | select(.name == $key).name')
  if [ "$rep" == "$TDH_DEMO_GIT_REPO" ]; then
    echo " ✓ Deleted repository https://githum.com/$TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO"
    gh repo delete $TDH_DEMO_GITHUB_USER/$TDH_DEMO_GIT_REPO --yes >/dev/null 2>&1
  fi
  
  if [ -d $HOME/workspace/$TDH_DEMO_GIT_REPO ]; then 
    echo " ✓ Deleted local git repository \$HOME/workspace/$TDH_DEMO_GIT_REPO"
    rm -rf $HOME/workspace/$TDH_DEMO_GIT_REPO
  fi

  echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE) on Cluster ($TAP_CLUSTER_DEV)"
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

  if [ "$TDH_DEPLOYMENT_TYPE"  == "tap-multicluster" ]; then
    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE) on Cluster ($TAP_CLUSTER_OPS)"
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

    echo " ✓ Cleanup Deployments in namespace '$TAP_DEVELOPER_NAMESPACE) on Cluster ($TAP_CLUSTER_RUN)"
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
  fi

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

