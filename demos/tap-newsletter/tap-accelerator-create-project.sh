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

tanzu accelerator list --from-context 2>/dev/null | awk '{ print $1 }' | sed -e 1d > /tmp/tap_accelerators.txt
if [ "$1" == "" ]; then 
  echo ""
  echo "Available TAP Accelerators"
  messageLine
  cat /tmp/tap_accelerators.txt
  echo 
  echo "USAGE: $0 <accelerator> [project-name]"
  echo 
  exit 0
else
  TAP_ACCELERATOR=$1
  cnt=$(egrep -c "^${TAP_ACCELERATOR}$" /tmp/tap_accelerators.txt)
  if [ $cnt -eq 0 ]; then 
    echo "ERROR: $TAP_ACCELERATOR is not a vailid accelerator"
    exit 1
  fi

  DEMO_APP_NAME=$(tanzu accelerator get tanzu-java-web-app 2>/dev/null | grep displayName | awk -F: '{ print $2 }' | sed 's/^  *//g')
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

# --- VERIFY SERVICES ---
verifyRequiredServices TDH_INGRESS_CONTOUR_ENABLED "Ingress Contour"
verifyRequiredServices TDH_SERVICE_GITEA           "Gitea Version Control"

# --- VERIFY GITHUB TAP VARIABLES ---
checkKubernetesServices github-tap

# --- CLUSTER CONFIGURATION ---
clearConfigMapCache
TDH_HARBOR_REGISTRY_DNS_HARBOR=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_DNS_HARBOR)
TDH_HARBOR_REGISTRY_ADMIN_PASSWORD=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_ADMIN_PASSWORD)
TDH_HARBOR_REGISTRY_ENABLED=$(getConfigMapCache tanzu-demo-hub TDH_HARBOR_REGISTRY_ENABLED)
TDH_LB_CONTOUR=$(getConfigMapCache tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
DOMAIN=${TDH_LB_CONTOUR}

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
deleteAppWorkload $DEMO_APP_ID $DEMO_APP_ID

# --- CLEANUP LEFTOVER FROM LAST RUN ---
[ -d $GIT_REPO_DIR ] && rm -rf $GIT_REPO_DIR
deleteNamespace $DEMO_APP_ID > /dev/null 2>&1

# --- CLEANUP GIT REPOSITORY ---
deleteGitHubRepository $GIT_REPO_NAM

messagePrint "create project ($TAP_PROJECT) from accelerator" "$TAP_ACCELERATOR"
tanzu accelerator generate $TAP_ACCELERATOR --server-url https://accelerator.$DOMAIN --output-dir /tmp > /dev/null

# --- CREATE GIT REPOSITORY ---
messagePrint "create githup repository" "https://$GIT_REPO_SERVER/$GIT_REPO_USER/$TAP_PROJECT"
createGitHubRepository $GITHUB_REPO

git -C /tmp clone https://$TAP_GITHUB_TOKEN@$GIT_REPO_SERVER/$GIT_REPO_USER/${GIT_REPO_NAM}.git > /dev/null 2>&1
git -C $GIT_REPO_DIR config --local user.email "$TAP_GITHUB_USER@example.com" > /dev/null 2>&1
git -C $GIT_REPO_DIR config --local user.email "$TAP_GITHUB_USER@example.com"
git -C $GIT_REPO_DIR config --local user.name $TAP_GITHUB_USER > /dev/null 2>&1

[ -d /tmp/app ] && rm -rf /tmp/app && mkdir -p /tmp/app
unzip /tmp/${TAP_ACCELERATOR}.zip -d /tmp/app  > /tmp/null 2>&1
(cd /tmp/app/$TAP_ACCELERATOR && tar cvf - . | tar -xf - -C $GIT_REPO_DIR) > /tmp/null 2>&1

messagePrint "update project workload file" "$GIT_REPO_DIR/config/workload.yaml"
[ -f $GIT_REPO_DIR/config/workload.yaml ] && mv $GIT_REPO_DIR/config/workload.yaml $GIT_REPO_DIR/config/workload_orig.yaml
ytt -f $GIT_REPO_DIR/config/workload_orig.yaml -f files/overlay.yaml \
  --data-value-yaml git.url="https://$GIT_REPO_SERVER/$GIT_REPO_USER/${DEMO_APP_ID}.git" \
  --data-value-yaml git.branch=$GIT_REPO_BRANCH > $GIT_REPO_DIR/config/workload.yaml

git -C $GIT_REPO_DIR add $GIT_REPO_DIR > /dev/null 2>&1
git -C $GIT_REPO_DIR commit -m "initial Load" > /dev/null 2>&1
git -C $GIT_REPO_DIR push > /dev/null 2>&1

clu=$(kubectl config current-context) 
messagePrint "create project kubernetes namespace" "$clu/$DEMO_APP_ID"
$TDHHOME/scripts/tap-create-developer-namespace.sh $DEMO_APP_ID > /dev/null 2>&1

kubectl get sa -n $DEMO_APP_ID -o json > /tmp/output.json 2>/dev/null 2>&1
SA_SECRET=$(jq -r --arg key "developer" '.items[] | select(.metadata.name == $key).secrets[].name' /tmp/output.json) 
if [ "$nam" != "developer" ]; then 
  kubectl apply -f files/developer-tole.yaml >/dev/null 2>&1
  kubectl apply -f files/developer-rolebinding.yaml >/dev/null 2>&1
  kubectl create serviceaccount developer -n $DEMO_APP_ID >/dev/null 2>&1
  kubectl get sa -n $DEMO_APP_ID -o json > /tmp/output.json >/dev/null 2>&1
  SA_SECRET=$(jq -r --arg key "developer" '.items[] | select(.metadata.name == $key).secrets[].name' /tmp/output.json) 
fi

TOKEN=$(kubectl -n $DEMO_APP_ID get secret "${SA_SECRET}" -o jsonpath='{.data.token}' | base64 -d) 

echo "TOKEN:$TOKEN"

exit

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

