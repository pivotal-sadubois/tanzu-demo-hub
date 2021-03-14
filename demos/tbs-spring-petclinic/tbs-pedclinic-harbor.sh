#!/bin/bash
# ============================================================================================
# File: ........: demo-privileged-access.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
# ============================================================================================

export NAMESPACE="spring-pedclinic-demo"
export TANZU_DEMO_HUB=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHPATH=$(cd "$(pwd)/$(dirname $0)/../../"; pwd)
export TDHDEMO=${TDHPATH}/demos/tbs-spring-petclinic

if [ -f $TANZU_DEMO_HUB/functions ]; then
  . $TANZU_DEMO_HUB/functions
else
  echo "ERROR: can ont find ${TANZU_DEMO_HUB}/functions"; exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '            ____             _               ____      _      ____ _ _       _        '
echo '           / ___| _ __  _ __(_)_ __   __ _  |  _ \ ___| |_   / ___| (_)_ __ (_) ___   '
echo '           \___ \|  _ \|  __| |  _ \ / _  | | |_) / _ \ __| | |   | | |  _ \| |/ __|  '
echo '            ___) | |_) | |  | | | | | (_| | |  __/  __/ |_  | |___| | | | | | | (__   '
echo '           |____/| .__/|_|  |_|_| |_|\__, | |_|   \___|\__|  \____|_|_|_| |_|_|\___|  '
echo '                 |_|                 |___/                                            '
echo '                                                                                      '
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

# --- LOAD LOCAL ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then 
  . ~/.tanzu-demo-hub.cfg
fi

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"
verifyRequiredServices TDH_SERVICE_BUILD_SERVICE   "Harbor Registry"

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_DEPLOYMENT_TYPE=$(getConfigMap tanzu-demo-hub TDH_DEPLOYMENT_TYPE)
TDH_MANAGED_BY_TMC=$(getConfigMap tanzu-demo-hub TDH_MANAGED_BY_TMC)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_LB_CONTOUR)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
TDH_LB_CONTOUR=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

if [ ! -x "/usr/local/bin/docker" ]; then 
  echo "ERROR: Docker binaries are not installed"
  echo "       => brew install docker"
  exit 1
fi

if [ "${TDH_TBS_DENO_PED_CLINIC_GIT}" == "" ]; then
  echo "  --------------------------------------------------------------------------------------------------------------"
  echo "  IMPORTANT: Please clone the Git Repo: https://github.com/spring-petclinic/spring-framework-petclinic.git"
  echo "             into your GitHub account and the TDH_TBS_DENO_PED_CLINIC_GIT with repository in ~/.tanzu-demo-hub.cfg"
  echo "             => export TDH_TBS_DENO_PED_CLINIC_GIT=https://github.com/<git-repository>.git"
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

# --- HARBOR CONFIG ---
TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMap tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
if [ "$TDH_HARBOR_REGISTRY_ENABLED" != "true" ]; then 
  echo "ERROR: The Harbor registry is required to run this demo"
  exit
else
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
kp image delete spring-petclinic > /dev/null 2>&1
rm -rf spring-petclinic  ## REMOVE GIT REPOSITORY (PET-CLINIC)
pkill com.docker.cli
kubectl delete namespace $NAMESPACE > /dev/null 2>&1

#prtHead "Create Secret (secret-registry-vmware) for Registry ($TDH_REGISTRY_VMWARE_NAME)"
#slntCmd "export REGISTRY_PASSWORD=$TDH_REGISTRY_VMWARE_PASS"
#execCmd "kp secret create secret-registry-vmware --registry $TDH_REGISTRY_VMWARE_NAME --registry-user $TDH_REGISTRY_VMWARE_USER"

prtHead "Create Secret (secret-registry-harbor) for Registry ($TDH_HARBOR_REGISTRY_DNS_HARBOR)"
export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD
slntCmd "export REGISTRY_PASSWORD=$TDH_HARBOR_REGISTRY_ADMIN_PASSWORD"
execCmd "kp secret create secret-registry-vmware --registry $TDH_HARBOR_REGISTRY_DNS_HARBOR --registry-user admin"

prtHead "Create Secret (secret-repo-git)"
execCmd "kp secret create secret-repo-git --git-url git@github.com --git-ssh-key $TDH_GITHUB_SSHKEY"
sleep 15

if [ -d spring-petclinic ]; then
  prtHead "Update Git Repository ($TDH_GITHUB_SSHKEY)"
  execCmd "git clone $TDH_TBS_DENO_PED_CLINIC_GIT"
else
  prtHead "Clone Git Repository ($TDH_GITHUB_SSHKEY)"
  execCmd "git clone $TDH_TBS_DENO_PED_CLINIC_GIT"
fi
execCmd "(cd spring-petclinic; git config --list)"

prtHead "Create TBS Image (spring-petclinic)"
execCmd "kp image create spring-petclinic --tag $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-petclinic \\
          --git $TDH_TBS_DENO_PED_CLINIC_GIT"

prtHead "Show the Build Process (spring-petclinic)"
execCmd "kp build logs spring-petclinic"

#################################################################################################################################3
######################################### RUN PETCLINIC CONTAINER ON LOCAL DOCKER ################################################
#################################################################################################################################3
echo -n "Do you want to deploy the (spring-petclinic:latest) container to local docker first ? (y/n): "; read local_docker
answer_provided="n"
while [ "${answer_provided}" == "n" ]; do
  if [ "${local_docker}" == "y" -o "${local_docker}" == "Y" ]; then break; fi
  if [ "${local_docker}" == "n" -o "${local_docker}" == "N" ]; then break; fi
  echo -n "Do you want to deploy the (spring-petclinic:latest) container to local docker first ? (y/n): "; read local_docker
done
echo

if [ "${local_docker}" == "y" -o "${local_docker}" == "Y" ]; then
  alias chrome="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"
  TMPEXE=/tmp/$$.sh; rm -f $TMPEXE
  TMPPID=/tmp/$$.pid; rm -f $TMPPID
  rm -f nohup.out 
  prtHead "This command runs the container and forwards the local port 8080 to the container port 8080"
  #echo "nohup docker run --rm -p 8080:8080 $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-petclinic:latest &" >  $TMPEXE
  echo "docker run --rm -p 8080:8080 $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-petclinic:latest > /tmp/log 2>&1 &" >  $TMPEXE
  echo "sleep 2" >> $TMPEXE
  echo "echo \$! > $TMPPID" >> $TMPEXE
  sh $TMPEXE > /dev/null 2>&1
  fakeCmd "docker run --rm -p 8080:8080 $TDH_HARBOR_REGISTRY_DNS_HARBOR/library/spring-petclinic:latest"
  
  read pid < $TMPPID

  prtHead "Open WebBrowser and verify the deployment"
  echo "     # --- Context Based Routing"
  echo "     => http://localhost:8080"
  echo ""
  echo "     presse 'return' to continue when ready"; read x

  #CHROME="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"
  #slntCmd "$CHROME http://localhost:8080"

  # --- CLEANUP ---
  kill $pid > /dev/null 2>&1
  pkill com.docker.cli
fi

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

prtHead "Create two service (echoserver-1 and echoserver-2) for the ingress tesing app"
execCmd "kubectl expose deployment petclinic --port=8080 -n $NAMESPACE"
execCmd "kubectl get svc,pods -n $NAMESPACE"

prtHead "Create a secret with the certificates of domain $DOMAIN"
execCmd "cat /tmp/https-secret.yaml"
execCmd "kubectl create -f /tmp/https-secret.yaml -n $NAMESPACE"

prtHead "Create the ingress route with context based routing"
execCmd "cat /tmp/https-ingress.yaml"
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
echo "     => cd $TDHDEMO/spring-petclinic"
echo "     => vi src/main/resources/messages/messages.properties        # CHANGE-THE MESSAGE TEXT"
echo "     => git add src/main/resources/messages/messages.properties   # ADD FILE TO LOCAL GIT REPO"
echo "     => git commit -m \"changed welcome message\"                 # COMIT THE CHANGE"
echo "     => git push"                                                 # PUSH TO GIT MASTER"
echo ""
echo "     # --- MAKE THE CHANGE WITH INTELLIJ-IDE ---"
echo "     => /Applications/IntelliJ\ IDEA\ CE.app/Contents/MacOS/idea $TDHDEMO/spring-petclinic"
echo "     => Edit: src/main/resources/messages/messages.properties     # CHANGE-THE MESSAGE TEXT"
echo "     => IntelliJ IDA -> GIT -> Commit                             # COMMIT CHANGE"
echo ""
echo "     presse 'return' to continue when ready"; read x

prtHead "Verify Change on GitHub (https://github.com/pivotal-sadubois/spring-petclinic.git)"
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







