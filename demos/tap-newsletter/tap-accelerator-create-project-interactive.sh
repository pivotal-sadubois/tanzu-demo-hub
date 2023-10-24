#!/bin/bash
# ============================================================================================
# File: ........: tap-create-project.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Create a Developer Space fpr a new TAP project
# Example ......: 
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit
# https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-F81E3535-C275-4DDE-B35F-CE759EA3B4A0.html#:~:text=vSphere%20with%20Tanzu%20offers%20a,machines%20in%20a%20vSphere%20Namespace.

export DEMODIR=tap-e2e-app-deploy
export TDHHOME=$HOME/tanzu-demo-hub
export TDHDEMO=$TDHHOME/demos/$DEMODIR

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

[ -f $TDHHOME/functions ] &&  . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

if [ "$1" == "" ]; then 
  tanzu accelerator generate 2>/dev/null
  echo 
  echo "USAGE: $0 <accelerator> [project-name]"
  echo 
else
  TAP_ACCELERATOR=$1
  [ "$2" != "" ] && TAP_PROJECT=$2 || TAP_PROJECT=$TAP_ACCELERATOR
fi

DEMO_APP_ID=$TAP_PROJECT
GIT_REPO_NAM="$TAP_ACCELERATOR"
GIT_REPO_DIR=/tmp/$GIT_REPO_NAM
GIT_REPO_BRANCH="master"
GIT_REPO_API_SERVER=https://api.github.com
GIT_REPO_SERVER=github.com
GIT_REPO_USER=$TAP_GITHUB_USER
GIT_REPO_TOKEN=$TAP_GITHUB_TOKEN

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '                _____  _    ____         ____        ____                             '
echo '               |_   _|/ \  |  _ \    ___|___ \ ___  |  _ \  ___ _ __ ___   ___        '
echo '                 | | / _ \ | |_) |  / _ \ __) / _ \ | | | |/ _ \  _   _ \ / _ \       '
echo '                 | |/ ___ \|  __/  |  __// __/  __/ | |_| |  __/ | | | | | (_) |      '
echo '                 |_/_/   \_\_|      \___|_____\___| |____/ \___|_| |_| |_|\___/       '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '               Tanzu Application Platform (TAP) - e2e Application Demo                '
echo '                      by Sacha Dubois and Steve Schmidt, VMware Inc                   '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

kubectl get configmap tanzu-demo-hub > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Configmap tanzu-demo-hub does not exist"; exit
fi

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"
verifyRequiredServices TDH_SERVICE_GITEA           "Gitea Version Control"

# --- VERIFY GITHUB TAP VARIABLES ---
checkKubernetesServices github-tap

# --- CLUSTER CONFIGURATION ---
clearConfigMapCache
TDH_SERVICE_GITEA_ADMIN_USER=$(getConfigMapCache tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_USER)
TDH_SERVICE_GITEA_ADMIN_PASS=$(getConfigMapCache tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_PASS)
TDH_SERVICE_GITEA_SERVER=$(getConfigMapCache tanzu-demo-hub TDH_SERVICE_GITEA_SERVER)
TDH_SERVICE_GITEA_SERVER_URL=$(getConfigMapCache tanzu-demo-hub TDH_SERVICE_GITEA_SERVER_URL)
TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
TDH_LB_CONTOUR=$(getConfigMapCache tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

# --- VERIFY TOOLS AND ACCESS ---
verify_docker
checkCLIcommands        BASIC
checkCLIcommands        DEMO_TOOLS
checkCLIcommands        TANZU_DATA

# --- DEMO APPLICATION CONFIG ---
DEMO_APP_NAME="Steeltoe Weather Forecast"
DEMO_APP_ID=weatherforecast-steeltoe

#################################################################################################################################
############################################# GITEA SETUP ADN DEMO REPRO ########################################################
#################################################################################################################################

GIT_REPO_ORG="tanzu"
GIT_REPO_NAM="$DEMO_APP_ID"
GIT_REPO_DIR=/tmp/$GIT_REPO_NAM
GIT_REPO_BRANCH="master"
GIT_REPO_API_SERVER=https://api.github.com
GIT_REPO_SERVER=github.com
GIT_REPO_USER=$TAP_GITHUB_USER
GIT_REPO_TOKEN=$TAP_GITHUB_TOKEN

# --- CLEANUP TANZU APPS ---
tanzu -n $DEMO_APP_ID apps workload list
tanzu -n $DEMO_APP_ID apps workload list --app $DEMO_APP_ID
#tanzu -n $DEMO_APP_ID apps workload delete $DEMO_APP_ID --yes 

# --- CLEANUP LEFTOVER FROM LAST RUN ---
[ -d $GIT_REPO_DIR ] && rm -rf $GIT_REPO_DIR
deleteNamespace $DEMO_APP_ID > /dev/null 2>&1

# --- CLEANUP GIT REPOSITORY ---
deleteGitHubRepository $GIT_REPO_NAM
#deleteGiteaRepo $GIT_REPO_ORG $GIT_REPO_NAM

# tanzu accelerator generate weatherforecast-steeltoe --server-url https://accelerator.apps-contour.vsptap.pcfsdu.com
# tanzu accelerator generate tanzu-java-web-app --server-url https://accelerator.apps-contour.vsptap.pcfsdu.com

prtHead "Create a new Application from a TAP Accelerator from the GUI"
prtText "Navigate to the TAP Gui on (https://tap-gui.$DOMAIN) and create a new project from an TAP Accelerator"
prtText " 1.) Enter as a Guest User"
prtText " 2.) Navigate to Application Accelerators (create)"
prtText "     - Search for App $DEMO_APP_NAME and press 'choose'"
prtText "     - Provide a new name (could be the same $DEMO_APP_NAME)"
prtText "     - Generate Accelerator and download => ${DEMO_APP_ID}.zip"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Create a new Application from a TAP Accelerator with the tanzu CLI"
execCmd "tanzu accelerator generate weatherforecast-steeltoe --server-url https://accelerator.$DOMAIN --output-dir /tmp"

prtHead "Navigate to the git Repistory (https://$GIT_REPO_SERVER/$GIT_REPO_USER)"
prtText "=> $GIT_REPO_NAM         # A new repository $GIT_REPO_NAM has been created for this demo"
#huhu

# --- CREATE GIT REPOSITORY ---
#createGiteaOrg  $GIT_REPO_ORG
#createGiteaRepo $GIT_REPO_ORG $GIT_REPO_NAM
createGitHubRepository $GITHUB_REPO

prtText ""
prtText "press 'return' to continue"; read x

#execCmd "git -C /tmp clone https://$TDH_SERVICE_GITEA_ADMIN_USER:$TDH_SERVICE_GITEA_ADMIN_PASS@$TDH_SERVICE_GITEA_SERVER/$GIT_REPO_ORG/${GIT_REPO_NAM}.git" # GITEA
execCmd "git -C /tmp clone https://$TAP_GITHUB_TOKEN@$GIT_REPO_SERVER/$GIT_REPO_USER/${GIT_REPO_NAM}.git"
git -C $GIT_REPO_DIR config --local user.email "$TAP_GITHUB_USER@example.com"
git -C $GIT_REPO_DIR config --local user.name "$TAP_GITHUB_USER"

prtHead "Unpack the Applicaiton template to the new GIT Repository"
execCmd "unzip /tmp/${DEMO_APP_ID}.zip -d /tmp"
slntCmd "git -C $GIT_REPO_DIR add $GIT_REPO_DIR"
execCmd "git -C $GIT_REPO_DIR commit -m \"initial Load\""
execCmd "git -C $GIT_REPO_DIR push"

prtHead "Create TAP Developer Workspace for $DEMO_APP_NAME"
prtText "Documentation: Set up developer namespaces to use installed packages"
prtText "https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.1/tap/GUID-install-components.html#setup"
prtText " - Create a Kubernetes Namespace ($DEMO_APP_ID)"
prtText " - Create a Secret object for Harbor Regesitry (registry-credentials)"
prtText " - Create a Secret object (tap-registry) for TAP"
prtText " - Create a ServiceAccount (default)"
prtText " - Create a RBAC Role object (default)" 
prtText " - Create a RBAC RoleBinding object (default)" 
prtText ""

execCmd "$TDHHOME/scripts/tap-create-developer-namespace.sh $DEMO_APP_ID"

prtHead "Start the TAP Supply Chain for app $DEMO_APP_ID"
execCmd "tanzu app workload create $DEMO_APP_ID \\
           --namespace $DEMO_APP_ID \\
           --git-repo https://$GIT_REPO_SERVER/$GIT_REPO_ORG/${GIT_REPO_NAM}.git \\
           --label \"apps.tanzu.vmware.com/workload-type=web\" \\
           --label \"app.kubernetes.io/part-of=$DEMO_APP_ID\" --yes"
prtText " home -> sss -> https://github.com/sample-accelerators/steeltoe-weatherforecast/tree/main/catalog/catalog-info.yaml"
prtText " home -> sss -> https://github.com/sample-accelerators/steeltoe-weatherforecast/tree/main/catalog/catalog-info.yaml"

prtHead "Start your IDE and Open the GIT Project"
prtText " => Start IntelliJ IDE: /Applications/IntelliJ*.app/Contents/MacOS/idea dontReopenProjects""
prtText "    - Open Project: https://$TDH_SERVICE_GITEA_SERVER/$GIT_REPO_ORG/${GIT_REPO_NAM}.git"

#tanzu app workload create tanzu-java-web-app --namespace dev-steve --local-path ./tanzu-java-web-app --source-image harbor.apps-contour.vsptap.sschmidt.ch/dev-steve/tanzu-java-web-app --label "apps.tanzu.vmware.com/workload-type=web" --label "app.kubernetes.io/part-of=tanzu-java-web-app"

prtText ""
echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"
exit

exit

