#!/bin/bash
# ============================================================================================
# File: ........: scgw-basic-routing.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Spring Cloud Gateway (SCGW) Demo with the Fortune Application
# ============================================================================================

export TDH_DEMO_DIR="spring-cloud-gateway"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="scgw-demo"

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

if [ -f $TDHHOME/functions ]; then
  . $TDHHOME/functions
else
  echo "ERROR: can ont find ${TDHHOME}/functions"; exit 1
fi

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                 ____             _                ____ _                 _           '
echo '                / ___| _ __  _ __(_)_ __   __ _   / ___| | ___  _   _  __| |          '
echo '                \___ \|  _ \|  __| |  _ \ / _  | | |   | |/ _ \| | | |/ _  |          '
echo '                 ___) | |_) | |  | | | | | (_| | | |___| | (_) | |_| | (_| |          '
echo '                |____/| .__/|_|  |_|_| |_|\__, |  \____|_|\___/ \__,_|\__,_|          '
echo '                      |_|                 |___/                                       '
echo '                            ____       _                                              '
echo '                           / ___| __ _| |_ _____      ____ _ _   _                    '
echo '                          | |  _ / _  | __/ _ \ \ /\ / / _  | | | |                   '
echo '                          | |_| | (_| | ||  __/\ V  V / (_| | |_| |                   '
echo '                           \____|\__,_|\__\___| \_/\_/ \__,_|\__, |                   '
echo '                                                             |___/                    '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                  Demonstration for VMware Tanzu Spring Cloud Gateway (SCGW)          '
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
runTDHtoolsDemos

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED   "Ingress Contour"
verifyRequiredServices TDH_HARBOR_REGISTRY_ENABLED   "Harbor Registry"

TDH_SERVICE_REGISTRY_DOCKER=$(getConfigMap tanzu-demo-hub TDH_SERVICE_REGISTRY_DOCKER)
TDH_SERVICE_REGISTRY_HARBOR=$(getConfigMap tanzu-demo-hub TDH_SERVICE_REGISTRY_HARBOR)
TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_LB_CONTOUR)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

# --- VERIFY TOOLS AND ACCESS ---
verify_docker
checkCLIcommands        BASIC
checkCLIcommands        DEMO_TOOLS
checkCLIcommands        TANZU_DATA

# --- READ ENVIRONMET VARIABLES ---
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

if [ "${TDH_TBS_DEMO_FORTUNE_GIT}" == "" ]; then
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please clone the Git Repo: https://github.com/parth-pandit/fortune-demo"
  echo "             into your GitHub account and the TDH_TBS_DEMO_FORTUNE_GIT with repository in ~/.tanzu-demo-hub.cfg"
  echo "             => export TDH_TBS_DEMO_FORTUNE_GIT=https://github.com/<git-repository>.git"
  echo "  --------------------------------------------------------------------------------------------------------------"
  exit 1
fi

if [ "${TDH_GITHUB_SSHKEY}" == "" ]; then
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please create a GITHUB Access ssh-key for your account at: https://github.com/settings/keys and"
  echo "             set the TDH_GITHUB_SSHKEY variable with your SSH Private Key file in ~/.tanzu-demo-hub.cfg"
  echo "             => export TDH_GITHUB_SSHKEY=~/.ssh/<github_ssh_private_key_file>" 
  echo "  --------------------------------------------------------------------------------------------------------------"
  exit 1
fi

if [ "$TDH_SERVICE_REGISTRY_HARBOR" == "true" -a "$TDH_SERVICE_REGISTRY_DOCKER" == "true" ]; then 
  echo "ERROR: This Demo requires a container registry either DockerHub or a deployed Harbor registry. Please enable "
  echo "       one of them in the releated deployment filea and redeploy the kubernetes cluster"
  echo "       TDH_SERVICE_REGISTRY_HARBOR=true     ## To use the Harbor Registry"
  echo "       TDH_SERVICE_REGISTRY_DOCKER=true     ## To use DockerHub"
  exit 1
fi

#################################################################################################################################
################################################### SETUP DEMO ENVIRONMENT ######################################################
#################################################################################################################################

TBS_SOURCE_APP=scgw-routing
TBS_SOURCE_DIR=/tmp/$TBS_SOURCE_APP 
TBS_GIT_REPO=https://github.com/parth-pandit/fortune-demo

[ -d $TBS_SOURCE_DIR ] && rm -rf $TBS_SOURCE_DIR; mkdir -p $TBS_SOURCE_DIR

##################################################################################################################################
############################################# INSTALL REDIS TROUGH KUBEAPPS ######################################################
##################################################################################################################################

txt_app=$(centerText 35 "$TBS_SOURCE_APP.$TDH_ENVNAME.$TDH_DOMAIN")
txt_dom=$(centerText 25 "(*.$TDH_ENVNAME.$TDH_DOMAIN)")
txt_ipa=$(centerText 25 "192.168.64.100")
txt_prt=$(centerText  8 "tcp/80")
txt_nsp=$(leftText 15 "$NAMESPACE")

prtText "                                                                                                                        "
prtText "                           Load Balancer                                                                                "
prtText "       DNS           $txt_ipa                                                                                           "
prtText "  (AWS Route53) ---> $txt_dom                                                                                           "
prtText "                                 |                                                                                      "
prtText "                          ________________          ________________                                                    "
prtText "                         |               |          |              |                                                    "
prtText "                         | Ingress Ctrl. |          |     SCGW     |                                                    "
prtText "                         |   (contour)   |          |   Operator   |                                                    "
prtText "                         |_______________|          |______________|                                                    "
prtText "                                 |                          |                                                           "
prtText "                          tcp/443 (https)                   |                                                           "
prtText "                                 |                          |                                                           "
prtText "  -------------------------------|--------------------------|---------------------------------------------------------- "
prtText "  Namespace: $txt_nsp     |                          |                                                                  "
prtText "                                 V                          V                                                           "
prtText "                         _________________          ________________                                                    "
prtText "                         |               |          |              |                                                    "
prtText "    TLS Termination ---- |    Ingress    | -------- | Spring Cloud | -----> http://github.com                           "
prtText "  (tanzu-demo-hub-tls)   |     Object    | $txt_prt |    Gateway   |                                                    "
prtText "                         |_______________|          |______________|                                                    "
prtText "                                                          | | |____________ basic-routing-gateway.yml                   "
prtText "                $txt_app       | |______________ basic-routing-route-config.yml                                         "
prtText "                              (tcp/80)                    |________________ basic-routing-mapping.yml                   "
prtText "  --------------------------------------------------------------------------------------------------------------------- "

# --- WE USE THE INTRODUCTION TIME FOR CLEANUP ----
kubectl delete namespace $NAMESPACE > /dev/null 2>&1

prtText ""
prtText "  presse 'return' to continue when ready"; read x

#################################################################################################################################
############################################### SPRING CLOUD GATEWAY (SCG) SETTUP ###############################################
#################################################################################################################################

prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "The spring cloud gateway operator is already deployed"
execCmd "kubectl get all -n spring-cloud-gateway"
prtText "The spring cloud gateway operator installed three kubernetes custom resources definitions"
prtText "These CRDs will be used to configure the gateway."
execCmd "kubectl get crds | grep springcloudgateway"

prtHead "Define a gateway instance"
cp files/basic-routing-gateway.yml $TBS_SOURCE_DIR
prtText "Inspect the $TBS_SOURCE_DIR/basic-routing-gateway.yml file it contains the YAML shown below which defines a spring cloud gateway instance."
execCat "$TBS_SOURCE_DIR/basic-routing-gateway.yml"
execCmd "kubectl -n $NAMESPACE apply -f $TBS_SOURCE_DIR/basic-routing-gateway.yml"
prtText "There should be a pod of the Spring Cloud Gateway running or being launched in the cluster's default namespace as shown in the output below."
execCmd "kubectl -n $NAMESPACE get all"

cp files/basic-routing-route-config.yml $TBS_SOURCE_DIR
prtText "Inspect the file $TBS_SOURCE_DIR/basic-routing-route-config.yml it contains gateway configuration CRD that proxies requests set the gateway to github."
prtText "Notice that this route configuration is generic."
execCat "$TBS_SOURCE_DIR/basic-routing-route-config.yml"
execCmd "kubectl -n $NAMESPACE apply -f $TBS_SOURCE_DIR/basic-routing-route-config.yml"

cp files/basic-routing-mapping.yml $TBS_SOURCE_DIR
prtText "Inspect the file basic-routing-mapping.yml notice that it points at the gateway instance we already deployed at the configuration"
prtText "defined in basic-routing-route-config.yml"
execCat "$TBS_SOURCE_DIR/basic-routing-mapping.yml"
execCmd "kubectl -n $NAMESPACE apply -f $TBS_SOURCE_DIR/basic-routing-mapping.yml"

#################################################################################################################################
################################################### CREATE TLS SECRET AND INGRESS ###############################################
#################################################################################################################################

kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.crt"' | base64 -d > /tmp/tanzu-demo-hub-crt.pem
kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.key"' | base64 -d > /tmp/tanzu-demo-hub-key.pem
TLS_CERTIFICATE=/tmp/tanzu-demo-hub-crt.pem
TLS_PRIVATE_KEY=/tmp/tanzu-demo-hub-key.pem

# --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then
  echo ""
  echo "ERROR: Certificate and Private-Key has not been specified. Please set"
  echo "       the following environment variables:"
  echo "       => export TLS_CERTIFICATE=<cert.pem>"
  echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
  echo ""
  exit 1
#else
#  verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
fi

# --- CONVERT CERTS TO BASE64 ---
if [ "$(uname)" == "Darwin" ]; then
  cert=$(base64 $TLS_CERTIFICATE)
  pkey=$(base64 $TLS_PRIVATE_KEY)
else
  cert=$(base64 --wrap=10000 $TLS_CERTIFICATE)
  pkey=$(base64 --wrap=10000 $TLS_PRIVATE_KEY)
fi

cat files/${TBS_SOURCE_APP}-tls-secret.yml  | sed -e "s/NAMESPACE/$NAMESPACE/g" > $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-tls-secret.yml
echo "  tls.crt: \"$cert\"" >> $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-tls-secret.yml
echo "  tls.key: \"$pkey\"" >> $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-tls-secret.yml

prtHead "Create a secret with the certificates of domain $DOMAIN"
kubectl delete secret tls-secret -n $NAMESPACE > /dev/null 2>&1
execCat "$TBS_SOURCE_DIR/${TBS_SOURCE_APP}-tls-secret.yml"
execCmd "kubectl create -f $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-tls-secret.yml -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
kubectl delete ingress ${TBS_SOURCE_APP}-routing-ingress -n $NAMESPACE > /dev/null 2>&1
cat files/${TBS_SOURCE_APP}-ingress.yml | sed \
  -e "s/DNS_DOMAIN/$DOMAIN/g" \
  -e "s/NAMESPACE/$NAMESPACE/g" \
  -e "s/TBS_SOURCE_APP/$TBS_SOURCE_APP/g" \
  -e "s/SERVICE_NAME/basic-routing-gateway/g" > $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-ingress.yml

execCat "$TBS_SOURCE_DIR/${TBS_SOURCE_APP}-ingress.yml"
execCmd "kubectl create -f $TBS_SOURCE_DIR/${TBS_SOURCE_APP}-ingress.yml -n $NAMESPACE"
#execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

#################################################################################################################################
################################################ TEST THE OUTCOME ###############################################################
#################################################################################################################################

prtHead "Open a WebBrowser and go to https://${TBS_SOURCE_APP}.${DOMAIN} and you should see the github site. The request"
prtText "are going to spring cloud gateway which is then sending them to github.com. Congrats you have managed to deploy"
prtText "a spring cloud gateway instance using a CRD. There are many more things that you can do with spring cloud gateway"
prtText "that we will discuss in the rest of the workshop this is just the start."

echo "     => https://${TBS_SOURCE_APP}.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                                   END OF THE DEMO                                              "
echo "                                           < --------------------------- >                                      "
echo "                                                THANKS FOR ATTENDING                                            "
echo "     -----------------------------------------------------------------------------------------------------------"








exit

#################################################################################################################################
############################################# CLONE THE GIT REPRO ###############################################################
#################################################################################################################################

[ -d $TBS_SOURCE_DIR ] && rm -rf $TBS_SOURCE_DIR; mkdir -p $TBS_SOURCE_DIR
prtHead "Clone Git Repository ($TBS_GIT_REPO) to $TBS_SOURCE_DIR"
execCmd "(cd /tmp; git clone $TDH_TBS_DEMO_FORTUNE_GIT $TBS_SOURCE_DIR)"
execCmd "(cd $TBS_SOURCE_DIR && git config --list)"

#################################################################################################################################
########################################## CONFIGURE TBS WITH THE HARBOR REGISTRY ###############################################
#################################################################################################################################
if [ "$TDH_SERVICE_REGISTRY_HARBOR" == "true" ]; then 
  TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
  TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
  TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
  
  if [ "$TDH_SERVICE_REGISTRY_HARBOR" == "true" ]; then 
    docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to login to registry"
      echo "       => docker login $TDH_HARBOR_REGISTRY_DNS_HARBOR -u admin -p $TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
      exit
    fi
  fi

  # --- CLEANUP ---
  kp secret delete secret-registry-vmware > /dev/null 2>&1
  kp secret delete secret-registry-harbor > /dev/null 2>&1
  kp secret delete secret-repo-git > /dev/null 2>&1
  kp image delete $TBS_SOURCE_APP > /dev/null 2>&1
  pkill com.docker.cli
  kubectl delete namespace $NAMESPACE > /dev/null 2>&1

  prtHead "Tanzu Build Service - Cluster Builders"
  prtText "A Builder is a Tanzu Build Service resource used to manage Cloud Native Buildpack builders. Builders contain a set of buildpacks"
  prtText "and a stack that will be used to create images (https://buildpacks.io/docs/concepts/components/builder)."
  prtText ""
  execCmd "kp clusterbuilder list"
  execCmd "kp clusterbuilder status base"

  #prtHead "Tanzu Build Service - ClusterStacks"
  #prtText "A ClusterStack is a cluster scoped resource that provides the build and run images for the Cloud Native Buildpack stack that will be used in a Builder."
  #prtText ""
  #execCmd "kp clusterstack list"
  #execCmd "kp clusterstack status default"

  prtHead "Tanzu Build Service - Cluster Store"
  prtText "The Cluster Store provides a collection of buildpacks that can be utilized by Builders. Build Service ships with a curated collection of"
  prtText "Tanzu buildpacks for Java, Nodejs, Go, PHP, nginx, and httpd and Paketo buildpacks for procfile, and .NET Core. Updates to these buildpacks "
  prtText "are provided on Tanzu Network."
  prtText ""
  execCmd "kp clusterstore list"
  execCmd "kp clusterstore status default"

  prtHead "Create Secret (secret-registry-harbor) for Registry ($TDH_HARBOR_REGISTRY_DNS_HARBOR)"
  export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD
  slntCmd "export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
  execCmd "kp secret create secret-registry-vmware --registry $TDH_HARBOR_REGISTRY_DNS_HARBOR --registry-user admin"

  prtHead "Create Secret (secret-repo-git)"
  execCmd "kp secret create secret-repo-git --git-url git@github.com --git-ssh-key $TDH_GITHUB_SSHKEY"
  sleep 15

  prtHead "Create TBS Image ($TBS_SOURCE_APP)"

  cnt=$(kp image list 2>/dev/null | egrep -c "^fortune")
  if [ $cnt -eq 0 ]; then
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $TDH_TBS_DEMO_FORTUNE_GIT --git-revision master"
  else
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $TDH_TBS_DEMO_FORTUNE_GIT --git-revision master"

    prtHead "Patch TBS Image ($TBS_SOURCE_APP)"
    execCmd "kp image patch $TBS_SOURCE_APP"
  fi

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build logs $TBS_SOURCE_APP"

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build list $TBS_SOURCE_APP"

  prtHead "View the new build Application Docker container ($TDH_REGISTRY_DOCKER_NAME/$TDH_REGISTRY_DOCKER_USER/$TBS_SOURCE_APP) in the Harbor Registry"
  prtText "=> https://$TDH_HARBOR_REGISTRY_DNS_HARBOR (admin/$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)"
  prtText ""
fi

#################################################################################################################################
########################################### CONFIGURE TBS WITH THE DOCKER-HUB REGISTRY ##########################################
#################################################################################################################################
if [ "$TDH_SERVICE_REGISTRY_DOCKER" == "true" ]; then
  TDH_REGISTRY_DOCKER_NAME=index.docker.io
  TDH_REGISTRY_DOCKER_PASS=$(getConfigMap tanzu-demo-hub TDH_REGISTRY_DOCKER_PASS)
  TDH_REGISTRY_DOCKER_USER=$(getConfigMap tanzu-demo-hub TDH_REGISTRY_DOCKER_USER)
  if [ "$TDH_REGISTRY_DOCKER_NAME" == "" -o "TDH_REGISTRY_DOCKER_PASS" == "" -o "TDH_REGISTRY_DOCKER_USER" == "" ]; then
    echo "ERROR: The docker.io registry credentials are required to run this demo. Please signup for an account and provide the credentials"
    echo "       => TDH_REGISTRY_DOCKER_USER  ## docker.io User"
    echo "       => TDH_REGISTRY_DOCKER_PASS  ## docker.io Password"
    exit 1
  else
    docker login docker.io -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS > /dev/null 2>&1; ret=$?
    docker login $TDH_REGISTRY_DOCKER_NAME -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to login to registry"
      echo "       => docker login $TDH_REGISTRY_DOCKER_NAME -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS"
      exit
    fi
  fi

  # --- CLEANUP ---
  kp secret delete secret-registry-vmware > /dev/null 2>&1
  kp secret delete secret-registry-docker > /dev/null 2>&1
  kp secret delete secret-repo-git > /dev/null 2>&1
  kp image delete $TBS_SOURCE_APP > /dev/null 2>&1
  pkill com.docker.cli
  kubectl delete namespace $NAMESPACE > /dev/null 2>&1

  prtHead "Tanzu Build Service - Cluster Builders"
  prtText "A Builder is a Tanzu Build Service resource used to manage Cloud Native Buildpack builders. Builders contain a set of buildpacks"
  prtText "and a stack that will be used to create images (https://buildpacks.io/docs/concepts/components/builder)."
  prtText ""
  execCmd "kp clusterbuilder list"
  execCmd "kp clusterbuilder status base"

  #prtHead "Tanzu Build Service - ClusterStacks"
  #prtText "A ClusterStack is a cluster scoped resource that provides the build and run images for the Cloud Native Buildpack stack that will be used in a Builder."
  #prtText ""
  #execCmd "kp clusterstack list"
  #execCmd "kp clusterstack status default"

  prtHead "Tanzu Build Service - Cluster Store"
  prtText "The Cluster Store provides a collection of buildpacks that can be utilized by Builders. Build Service ships with a curated collection of"
  prtText "Tanzu buildpacks for Java, Nodejs, Go, PHP, nginx, and httpd and Paketo buildpacks for procfile, and .NET Core. Updates to these buildpacks "
  prtText "are provided on Tanzu Network."
  prtText ""
  execCmd "kp clusterstore list"
  execCmd "kp clusterstore status default"

  prtHead "Create Secret (secret-registry-docker) for Registry (docker.io)"
  slntCmd "export DOCKER_PASSWORD=$(maskPassword \"$TDH_REGISTRY_DOCKER_PASS\")"
  export DOCKER_PASSWORD=$TDH_REGISTRY_DOCKER_PASS
  execCmd "kp secret create secret-registry-docker --dockerhub $TDH_REGISTRY_DOCKER_USER"

  prtHead "Create Secret (secret-repo-git)"
  execCmd "kp secret create secret-repo-git --git-url git@github.com --git-ssh-key $TDH_GITHUB_SSHKEY"
  sleep 15

  prtHead "Create TBS Image ($TBS_SOURCE_APP)"
  cnt=$(kp image list 2>/dev/null | egrep -c "^fortune") 
  if [ $cnt -eq 0 ]; then 
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_REGISTRY_DOCKER_NAME/$TDH_REGISTRY_DOCKER_USER/$TBS_SOURCE_APP --git $TDH_TBS_DEMO_FORTUNE_GIT --git-revision master"
  else
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_REGISTRY_DOCKER_NAME/$TDH_REGISTRY_DOCKER_USER/$TBS_SOURCE_APP --git $TDH_TBS_DEMO_FORTUNE_GIT --git-revision master"

    prtHead "Patch TBS Image ($TBS_SOURCE_APP)"
    execCmd "kp image patch $TBS_SOURCE_APP"
  fi

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build logs $TBS_SOURCE_APP"

  prtHead "View the new build Application Docker container ($TDH_REGISTRY_DOCKER_NAME/$TDH_REGISTRY_DOCKER_USER/$TBS_SOURCE_APP) in Docker Hub"
  prtText "=> https://$TDH_REGISTRY_DOCKER_NAME (User: $TDH_REGISTRY_DOCKER_USER)"
  prtText ""

fi


##################################################################################################################################
############################################# INSTALL REDIS TROUGH KUBEAPPS ######################################################
##################################################################################################################################

kubectl delete namespace $NAMESPACE > /dev/null 2>&1
prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "Tanzu Application Catalog (TAC)" 
prtText "The commercial offering of the Bitnami Application Catalog"
prtText "  - Pre-packaged applications and application components delivered as Docker containers and Helm charts"
prtText "  - Containers can be built on your “golden” OS image, or you can select one maintained with best practices by VMware"
prtText "  - Containers are kept up-to-date automatically; any change to upstream code or base OS triggers rebuilding and retesting"
prtText "  - Continuously updated Helm charts for container orchestration included"
prtText ""
prtText "  => https://tac.bitnami.com/apps"
prtText ""
prtText "  presse 'return' to continue when ready"; read x

prtHead "Manage Kubernetes applications with Kubeapp"
prtText "Kubeapp manages applications comming from Bitnami Application Catalog or Tanzu Application Catalog (TAC)"
prtText "  a.) Open Kubeapps (https://kubeapps.$DOMAIN) in a browser Window."
prtText "       => Login with API Token (see below)" 
prtText ""

messageLine
echo "Kubeapps Token: "
kubectl get secret $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
messageLine

prtText ""
prtHead "Install Redis from the Bitnami Application Catalog interactivly with kubeapps"
prtText "  a.) In 'Current Contexts' (top-right-corner) change the Namespace to tbs-kubeapps-fortune"
prtText "  b.) Press 'deploy', search for 'Redis' and press 'deploy' again"
prtText "        - Name: fortune"
prtText "        - Redis architecture: replication"
prtText "        - Use Password Authentication: disabled"
prtText "        - Enable Persistence: enabled"
prtText "        - Number of Replicas: 1"
prtText "        - Master and Replica: 2 GB Persistent Volume Size"
prtText "        - Enable Init Container: true"
prtText ""
prtText "  presse 'return' to continue when ready"; read x

cnt=$(helm list -n $NAMESPACE | egrep -c "^fortune")
if [ $cnt -eq 0 ]; then 
  prtHead "Install Redis from the Bitnami Application Catalog with helm"
  execCmd "helm install fortune -n $NAMESPACE bitnami/redis -f files/redis-helm-values.yaml"
fi

# --- WAIT UNTIL HELM CHART IS INSTALLED ---
cnt=0; stt=1
while [ $cnt -lt 5 -a $stt -ne 0 ]; do
  stt=$(kubectl get pods -n $NAMESPACE 2>/dev/null | egrep "^fortune-redis" | grep -vc "Running") 
  [ $stt -eq 0 ] && break
  sleep 10
done

execCmd "kubectl get pods -n $NAMESPACE"
execCmd "helm list -A"

##################################################################################################################################
######################################### DEPLOY APPLICATION CONTAINER ON KUBERNETES #############################################
##################################################################################################################################

kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.crt"' | base64 -d > /tmp/tanzu-demo-hub-crt.pem
kubectl get secret tanzu-demo-hub-tls -o json | jq -r '.data."tls.key"' | base64 -d > /tmp/tanzu-demo-hub-key.pem
TLS_CERTIFICATE=/tmp/tanzu-demo-hub-crt.pem
TLS_PRIVATE_KEY=/tmp/tanzu-demo-hub-key.pem

# --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then
  echo ""
  echo "ERROR: Certificate and Private-Key has not been specified. Please set"
  echo "       the following environment variables:"
  echo "       => export TLS_CERTIFICATE=<cert.pem>"
  echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
  echo ""
  exit 1
#else
#  verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
fi

if [ "$TDH_SERVICE_REGISTRY_DOCKER" == "true" ]; then
  IMAGE_PATH="$TDH_REGISTRY_DOCKER_NAME/$TDH_REGISTRY_DOCKER_USER/$TBS_SOURCE_APP:latest"
else
  IMAGE_PATH="$TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP:latest"
fi

prtHead "Create deployment for the fortune app"
cat files/fortune-app.yaml | sed -e "s+FORTUNE_DOCKER_IMAGE+$IMAGE_PATH+g" -e "s/NAMESPACE/$NAMESPACE/g" > $TBS_SOURCE_DIR/fortune-app.yaml
execCat "$TBS_SOURCE_DIR/fortune-app.yaml"
execCmd "kubectl create -f $TBS_SOURCE_DIR/fortune-app.yaml"
execCmd "kubectl get pods,svc -n $NAMESPACE"

prtHead "Wait for the deployment rollout (deployment/fortune-app) to be compleed"
execCmd "kubectl -n $NAMESPACE rollout status -w  deployment/fortune-app"

# --- CONVERT CERTS TO BASE64 ---
if [ "$(uname)" == "Darwin" ]; then
  cert=$(base64 $TLS_CERTIFICATE)
  pkey=$(base64 $TLS_PRIVATE_KEY)
else
  cert=$(base64 --wrap=10000 $TLS_CERTIFICATE)
  pkey=$(base64 --wrap=10000 $TLS_PRIVATE_KEY)
fi

cat files/https-secret.yaml | sed -e "s/NAMESPACE/$NAMESPACE/g" > $TBS_SOURCE_DIR/https-secret.yaml
echo "  tls.crt: \"$cert\"" >> $TBS_SOURCE_DIR/https-secret.yaml
echo "  tls.key: \"$pkey\"" >> $TBS_SOURCE_DIR/https-secret.yaml

prtHead "Create a secret with the certificates of domain $DOMAIN"
execCat "$TBS_SOURCE_DIR/https-secret.yaml"
execCmd "kubectl create -f $TBS_SOURCE_DIR/https-secret.yaml -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
cat files/https-ingress.yaml | sed -e "s/DNS_DOMAIN/$DOMAIN/g" -e "s/NAMESPACE/$NAMESPACE/g" > $TBS_SOURCE_DIR/https-ingress.yaml
execCat "$TBS_SOURCE_DIR/https-ingress.yaml"
execCmd "kubectl create -f $TBS_SOURCE_DIR/https-ingress.yaml -n $NAMESPACE"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://fortune.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

##################################################################################################################################
############################################ CHANGE PETCLINIC CODE AND REDEPLOY ##################################################
##################################################################################################################################

prtHead "Modify the text in (fortune/src/main/resources/static/index.html)"
echo "     # --- MAKE THE CHANGE ON CLI ---"
echo "     => cd $TBS_SOURCE_DIR"
echo "     => vi src/main/resources/static/index.html                   # CHANGE-THE MESSAGE TEXT"
echo "        <p>Find out what the future holds...</p>"                 # REPLACE THE TEXT WITH SOMETHING ELSE"
echo "     => git add src/main/resources/static/index.html              # ADD FILE TO LOCAL GIT REPO"
echo "     => git commit -m \"changed welcome message\"                   # COMIT THE CHANGE"
echo "     => git push"                                                 # PUSH TO GIT MASTER"
echo ""
echo "     # --- MAKE THE CHANGE WITH INTELLIJ-IDE ---"
echo "     => /Applications/IntelliJ\ IDEA\ CE.app/Contents/MacOS/idea  $TBS_SOURCE_DIR"
echo "     => Edit: src/main/resources/static/index.html                # CHANGE-THE MESSAGE TEXT"
echo "     => IntelliJ IDA -> GIT -> Commit                             # COMMIT CHANGE"
echo "     => IntelliJ IDA -> GIT -> Push                               # PUSH TO THE GIT REPOSITORY ON GITHUB"
echo ""
echo "     presse 'return' to continue when ready"; read x

prtHead "Verify Change on GitHub ($TDH_TBS_DEMO_FORTUNE_GIT)"
echo "     => Navigate to src/main/resources/static/index.html"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "     # --- VERIFY CHANGE ---"

#prtHead "Patch TBS Image ($TBS_SOURCE_APP)"
#execCmd "kp image patch $TBS_SOURCE_APP --local-path=$TBS_SOURCE_DIR"

prtHead "Show the Build Process ($TBS_SOURCE_APP)"
execCmd "kp build list $TBS_SOURCE_APP"

prtHead "Show the Build Process ($TBS_SOURCE_APP)"
execCmd "kp build logs $TBS_SOURCE_APP"

prtHead "Show the Build Process ($TBS_SOURCE_APP)"
execCmd "kp build list $TBS_SOURCE_APP"

prtHead "Show the Build Process (${TBS_SOURCE_APP}-app)"
execCmd "kubectl -n $NAMESPACE rollout restart deployment/${TBS_SOURCE_APP}-app"

prtHead "Wait for the deployment rollout (deployment/${TBS_SOURCE_APP}-app) to be compleed"
execCmd "kubectl -n $NAMESPACE rollout status -w  deployment/${TBS_SOURCE_APP}-app"

prtHead "Open WebBrowser and verify the deployment (clear the browser cache if changes are not shown)"
echo "     => https://${TBS_SOURCE_APP}.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                                   END OF THE DEMO                                              "
echo "                                           < --------------------------- >                                      "
echo "                                                THANKS FOR ATTENDING                                            "
echo "     -----------------------------------------------------------------------------------------------------------"

exit







