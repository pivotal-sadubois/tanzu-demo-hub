#!/bin/bash
# ============================================================================================
# File: ........: tbs-kubeapps-fortune-github.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Tanzu Build Service (TBS) Demo with the Fortune Application
# ============================================================================================

export TDH_DEMO_DIR="tbs-kubeapps-fortune"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tbs-kubeapps-fortune"

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
echo '                      _____                       ____        _ _     _               '
echo '                     |_   _|_ _ _ __  _____   _  | __ ) _   _(_) | __| |              '
echo '                       | |/ _  |  _ \|_  / | | | |  _ \| | | | | |/ _  |              '
echo '                       | | (_| | | | |/ /| |_| | | |_) | |_| | | | (_| |              '
echo '                       |_|\__,_|_| |_/___|\__,_| |____/ \__,_|_|_|\__,_|              '
echo '                                                                                      '
echo '                ____                  _            ____                               '
echo '               / ___|  ___ _ ____   _(_) ___ ___  |  _ \  ___ _ __ ___   ___          '
echo '               \___ \ / _ \  __\ \ / / |/ __/ _ \ | | | |/ _ \  _   _ \ / _ \         '
echo '                ___) |  __/ |   \ V /| | (_|  __/ | |_| |  __/ | | | | | (_) |        '
echo '               |____/ \___|_|    \_/ |_|\___\___| |____/ \___|_| |_| |_|\___/         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                        Demonstration for VMware Tanzu Build Service (TBS)            '
echo '                            by Sacha Dubois / Steve Schmidt, VMware Inc               '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
runTDHtoolsDemos_new
#runTDHtoolsDemos

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"
verifyRequiredServices TDH_SERVICE_BUILD_SERVICE   "Harbor Registry"
verifyRequiredServices TDH_SERVICE_GITEA           "Harbor Registry"

# --- GITEA CONFIGURATION ---
TDH_SERVICE_GITEA_ADMIN_USER=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_USER)
TDH_SERVICE_GITEA_ADMIN_PASS=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_PASS)
TDH_SERVICE_GITEA_SERVER=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_SERVER)
TDH_SERVICE_GITEA_SERVER_URL=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_SERVER_URL)

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
#[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# https://github.com/pivotal-sadubois/fortune-demo
TDH_SERVICE_REGISTRY_HARBOR=true
TBS_SOURCE_APP=fortune
TBS_SOURCE_DIR=/tmp/$TBS_SOURCE_APP

GIT_MIRR_ORG="sync"
GIT_REPO_ORG="tanzu"
GIT_REPO_NAM="fortune-demo"
GIT_REPO_SOURCE=https://github.com/parth-pandit/fortune-demo
GIT_REPO_TARGET=http://$TDH_SERVICE_GITEA_SERVER/$GIT_REPO_ORG/${GIT_REPO_NAM}.git

#echo "TDH_TBS_DEMO_FORTUNE_GIT:$TDH_TBS_DEMO_FORTUNE_GIT"
#echo "GIT_REPO_TARGET:$GIT_REPO_TARGET"
#echo "TDH_TBS_DEMO_FORTUNE_GIT:$TDH_TBS_DEMO_FORTUNE_GIT"

#################################################################################################################################
############################################# GITEA SETUP ADN DEMO REPRO ########################################################
#################################################################################################################################
createGiteaOrg   $GIT_MIRR_ORG "Tanzu Organisation"
createGiteaOrg   $GIT_REPO_ORG "Tanzu Organisation"
giteaMirrorRepo  $GIT_REPO_SOURCE $GIT_MIRR_ORG $GIT_REPO_NAM
giteaForkRepo    sync fortune-demo fortune-demo tanzu

prtHead "Login to the Git Envifonment (Gitea)"
prtText " => http://$TDH_SERVICE_GITEA_SERVER"
prtText "    ($TDH_SERVICE_GITEA_ADMIN_USER/$TDH_SERVICE_GITEA_ADMIN_PASS)"
prtText " => tanzu/fortune-demo   # Fortune Demo Repository"
prtText ""
prtText "press 'return' to continue"; read x

#################################################################################################################################
############################################# CLONE THE GIT REPRO ###############################################################
#################################################################################################################################

echo "GIT_REPO_TARGET:$GIT_REPO_TARGET"

#[ -d $TBS_SOURCE_DIR ] && rm -rf $TBS_SOURCE_DIR
prtHead "Clone Git Repository ($GIT_REPO_TARGET) to $TBS_SOURCE_DIR"
execCmd "(cd /tmp; git clone $GIT_REPO_TARGET $TBS_SOURCE_DIR)"
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
  for n in $(kp secret list list | sed -e '1d' -e '$d' | awk '{ print $1 }'); do
    kp secret delete $n > /dev/null 2>&1
  done
  
  #kp secret delete secret-registry-vmware > /dev/null 2>&1
  #kp secret delete secret-registry-harbor > /dev/null 2>&1
  kp secret delete secret-repo-git > /dev/null 2>&1
  kp image delete $TBS_SOURCE_APP > /dev/null 2>&1
  pkill com.docker.cli
  kubectl delete namespace $NAMESPACE > /dev/null 2>&1

  prtHead "Create Secret (secret-registry-harbor) for Registry ($TDH_HARBOR_REGISTRY_DNS_HARBOR)"
  export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD
  slntCmd "export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
  execCmd "kp secret create secret-registry-vmware --registry $TDH_HARBOR_REGISTRY_DNS_HARBOR --registry-user admin"

  prtHead "Create Secret (secret-repo-git)"
  export GIT_PASSWORD=$TDH_SERVICE_GITEA_ADMIN_PASS
  slntCmd "export GIT_PASSWORD=$TDH_SERVICE_GITEA_ADMIN_PASS"
  execCmd "kp secret create secret-repo-git --git-url https://$TDH_SERVICE_GITEA_SERVER --git-user $TDH_SERVICE_GITEA_ADMIN_USER"

  sleep 15

  prtHead "Create TBS Image ($TBS_SOURCE_APP)"

  cnt=$(kp image list 2>/dev/null | egrep -c "^fortune")
  if [ $cnt -eq 0 ]; then
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $GIT_REPO_TARGET --git-revision master"
  else
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $GIT_REPO_TARGET --git-revision master"

    prtHead "Patch TBS Image ($TBS_SOURCE_APP)"
    execCmd "kp image patch $TBS_SOURCE_APP"
  fi

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build logs $TBS_SOURCE_APP"

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build list $TBS_SOURCE_APP"
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

cnt=$(helm list -A | egrep -c "^fortune")
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
echo "     => File -> New -> Project from Version Control" 
echo "           Version Control .:: Git"
echo "           Url ..............: $GIT_REPO_TARGET"
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







