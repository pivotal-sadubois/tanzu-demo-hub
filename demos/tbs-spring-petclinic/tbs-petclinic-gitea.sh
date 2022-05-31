#!/bin/bash
# ============================================================================================
# File: ........: tbs-petclinic-harbor.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Tanzu Build Service (TBS) Demo with the  Spring Petclinic Application
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit
export TDH_DEMO_DIR="tbs-spring-petclinic"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tbs-spring-petclinic"

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
echo '            ____             _               ____      _      ____ _ _       _        '
echo '           / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___| |_   / ___| (_)_ __ (_) ___   '
echo '           \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \ __| | |   | | |  _ \| |/ __|  '
echo '            ___) | |_) | |  | | | | | (_| | |  __/  __/ |_  | |___| | | | | | | (__   '
echo '           |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__|  \____|_|_|_| |_|_|\___|  '
echo '                 |_|                 |___/                                            '
echo '                                   ____                                               '
echo '                                  |  _ \  ___ _ __ ___   ___                          '
echo '                                  | | | |/ _ \  _   _ \ / _ \                         '
echo '                                  | |_| |  __/ | | | | | (_) |                        '
echo '                                  |____/ \___|_| |_| |_|\___/                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                        Demonstration for VMware Tanzu Build Service (TBS)            '
echo '                                   by Sacha Dubois, VMware Inc                        '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- RUN SCRIPT INSIDE TDH-TOOLS OR NATIVE ON LOCAL HOST ---
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

# https://github.com/spring-projects/spring-petclinic
TDH_SERVICE_REGISTRY_HARBOR=true
TBS_SOURCE_APP=spring-petclinic
TBS_SOURCE_DIR=/tmp/$TBS_SOURCE_APP

GIT_MIRR_ORG="sync"
GIT_REPO_ORG="tanzu"
GIT_REPO_NAM="spring-petclinic"
GIT_REPO_BRANCH="master"
GIT_REPO_SOURCE=https://github.com/spring-petclinic/spring-framework-petclinic.git
GIT_REPO_TARGET=https://$TDH_SERVICE_GITEA_SERVER/$GIT_REPO_ORG/${GIT_REPO_NAM}.git

#################################################################################################################################
############################################# GITEA SETUP ADN DEMO REPRO ########################################################
#################################################################################################################################
createGiteaOrg   $GIT_MIRR_ORG "Tanzu Organisation"
createGiteaOrg   $GIT_REPO_ORG "Tanzu Organisation"
giteaMirrorRepo  $GIT_REPO_SOURCE $GIT_MIRR_ORG $GIT_REPO_NAM
giteaForkRepo    sync $GIT_REPO_NAM $GIT_REPO_NAM tanzu

prtHead "Login to the Git Envifonment (Gitea)"
prtText " => http://$TDH_SERVICE_GITEA_SERVER"
prtText "    ($TDH_SERVICE_GITEA_ADMIN_USER/$TDH_SERVICE_GITEA_ADMIN_PASS)"
prtText " => tanzu/$TBS_SOURCE_APP   # $TBS_SOURCE_APP Demo Repository"
prtText ""
prtText "press 'return' to continue"; read x

#################################################################################################################################
############################################# CLONE THE GIT REPRO ###############################################################
#################################################################################################################################

[ -d $TBS_SOURCE_DIR ] && rm -rf $TBS_SOURCE_DIR
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
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $GIT_REPO_TARGET --git-revision $GIT_REPO_BRANCH"
  else
    execCmd "kp image create $TBS_SOURCE_APP --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP --git $GIT_REPO_TARGET --git-revision $GIT_REPO_BRANCH"

    prtHead "Patch TBS Image ($TBS_SOURCE_APP)"
    execCmd "kp image patch $TBS_SOURCE_APP"
  fi

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  echo "     kp build logs $TBS_SOURCE_APP"
  kp build logs $TBS_SOURCE_APP
  echo

  prtHead "Show the Build Process ($TBS_SOURCE_APP)"
  execCmd "kp build list $TBS_SOURCE_APP"

fi
#################################################################################################################################3
######################################### RUN PETCLINIC CONTAINER ON LOCAL DOCKER ################################################
#################################################################################################################################3

prtHead "Run the docker container on the local workstation to test"
prtText "This command runs the container and forwards the local port 8080 to the container port 8080"
prtText "Run the following command in a seperate terminsal:"
prtText "=> docker run --rm -p 8080:8080 $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/$TBS_SOURCE_APP:latest"
prtText ""
  
prtHead "Open WebBrowser and verify the deployment"
echo "     # --- Context Based Routing"
echo "     => http://localhost:8080"
echo ""
echo "     presse 'return' to continue when ready"; read x

#################################################################################################################################3
######################################### DEPLOY PETCLINIC CONTAINER ON KUBERNETES ###############################################
#################################################################################################################################3

kubectl delete namespace $NAMESPACE > /dev/null 2>&1
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

# --- GENERATE INGRES FILES ---
cat files/https-secret.yaml | sed -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/https-secret.yaml
echo "  tls.crt: \"$cert\"" >> /tmp/https-secret.yaml
echo "  tls.key: \"$pkey\"" >> /tmp/https-secret.yaml

# --- PREPARATION ---
cat files/https-ingress.yaml | sed -e "s/DNS_DOMAIN/$DOMAIN/g" -e "s/NAMESPACE/$NAMESPACE/g" > /tmp/https-ingress.yaml

prtHead "Create seperate namespace to host the Ingress Demo"
execCmd "kubectl create namespace $NAMESPACE"

prtHead "Create deployment for the ingress tesing app"
execCmd "kubectl create deployment petclinic --image=$TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-petclinic:latest --port=8080 -n $NAMESPACE"
execCmd "kubectl get pods -n $NAMESPACE"

prtHead "Wait for the deployment rollout (deployment/petclinic) to be compleed"
execCmd "kubectl -n $NAMESPACE rollout status -w  deployment/petclinic"

prtHead "Expose the petclinic service of type ClusterIP" 
execCmd "kubectl expose deployment petclinic --port=8080 -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Create a secret with the certificates of domain $DOMAIN"
execCat "/tmp/https-secret.yaml"
execCmd "kubectl create -f /tmp/https-secret.yaml -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
execCat "/tmp/https-ingress.yaml"
execCmd "kubectl create -f /tmp/https-ingress.yaml -n $NAMESPACE"
execCmd "kubectl get ingress,svc,pods -n $NAMESPACE"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://petclinic.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

##################################################################################################################################
############################################ CHANGE PETCLINIC CODE AND REDEPLOY ##################################################
##################################################################################################################################

prtHead "Modify the text in (spring-petclinic/src/main/resources/messages/messages.properties"
echo "     # --- MAKE THE CHANGE ON CLI ---"
echo "     => cd $TBS_SOURCE_DIR"
echo "     => vi src/main/resources/messages/messages.properties        # CHANGE-THE MESSAGE TEXT"
echo "     => git add src/main/resources/messages/messages.properties   # ADD FILE TO LOCAL GIT REPO"
echo "     => git commit -m \"changed welcome message\"                 # COMIT THE CHANGE"
echo "     => git push"                                                 # PUSH TO GIT MASTER"
echo ""
echo "     # --- MAKE THE CHANGE WITH INTELLIJ-IDE ---"
echo "     => /Applications/IntelliJ\ IDEA\ CE.app/Contents/MacOS/idea  $TBS_SOURCE_DIR"
echo "     => Edit: src/main/resources/messages/messages.properties     # CHANGE-THE MESSAGE TEXT"
echo "     => IntelliJ IDA -> GIT -> Commit                             # COMMIT CHANGE"
echo "     => IntelliJ IDA -> GIT -> Push                               # PUSH TO THE GIT REPOSITORY ON GITHUB"
echo ""
echo "     presse 'return' to continue when ready"; read x

prtHead "Verify Change on GitHub ($TDH_TBS_DEMO_PET_CLINIC_GIT)"
echo "     => Navigate to srv/main/resources/messages/messages.properties"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "     # --- VERIFY CHANGE ---"
prtHead "Show the Build Process (spring-petclinic)"
execCmd "kp build list spring-petclinic"

prtHead "Show the Build Process (spring-petclinic)"
execCmd "kp build logs spring-petclinic"

prtHead "Show the Build Process (spring-petclinic)"
execCmd "kubectl -n $NAMESPACE rollout restart deployment/petclinic"

prtHead "Wait for the deployment rollout (deployment/petclinic) to be compleed"
execCmd "kubectl -n $NAMESPACE rollout status -w  deployment/petclinic"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://petclinic.${DOMAIN}"
echo ""
echo "     presse 'return' to continue when ready"; read x

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                                   END OF THE DEMO                                              "
echo "                                           < --------------------------- >                                      "
echo "                                                THANKS FOR ATTENDING                                            "
echo "     -----------------------------------------------------------------------------------------------------------"

exit







