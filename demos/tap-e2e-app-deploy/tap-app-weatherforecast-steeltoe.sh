#!/bin/bash
# ============================================================================================
# File: ........: deploy-virtual-machine.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy a Virtual Machine trough vm-service
# Example ......: https://cloudinit.readthedocs.io/en/latest/topics/examples.html
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

# https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-F81E3535-C275-4DDE-B35F-CE759EA3B4A0.html#:~:text=vSphere%20with%20Tanzu%20offers%20a,machines%20in%20a%20vSphere%20Namespace.
export TDH_DEMO_DIR="tkg-vsphere-service"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export NAMESPACE="tkg-vsphere-service"
export GUEST_CLUSTER=tkg-cluster-1

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*

[ -f $TDHHOME/functions ] &&  . $TDHHOME/functions
[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

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

TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
TDH_INGRESS_CONTOUR_LB_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
TDH_INGRESS_CONTOUR_LB_IP=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_IP)
TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
DOMAIN=${TDH_INGRESS_CONTOUR_LB_DOMAIN}

APP_NAME=weatherforecast-steeltoe

# --- CLEANUP FROM PREVIOUS RUN ---
rm -rf /tmp/$APP_NAME /tmp/${APP_NAME}.zip
deleteNamespace $APP_NAME > /dev/null 2>&1
deleteGiteaRepo tap $APP_NAME

prtHead "Navigate to the TAP Gui on (http://tap-gui.$DOMAIN) and create a new project from an TAP Accelerator" 
prtText " - create => $APP_NAME"
prtText " - download => ${APP_NAME}.zip"
prtText ""
prtText "press 'return' to continue"; read x

cp files/${APP_NAME}.zip /tmp

prtHead "Create TAP Developer Workspace for $APP_NAME"
prtText "Documentation: Set up developer namespaces to use installed packages"
prtText "https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.1/tap/GUID-install-components.html#setup"

prtText " - Create a Kubernetes Namespace ($APP_NAME)"
prtText " - Create a Secret object for Harbor Regesitry (registry-credentials)"
prtText " - Create a Secret object (tap-registry) for TAP"
prtText " - Create a ServiceAccount (default)"
prtText " - Create a RBAC Role object (default)" 
prtText " - Create a RBAC RoleBinding object (default)" 
prtText ""
execCmd "cd $TDHHOME/scripts && ./tap-create-developer-namespace.sh $APP_NAME 2>/dev/null"

prtHead "Create a GIT Repo for $APP_NAME"
prtText " - Create a new Organization (tap) in Gitea"
prtText " - Create a new Repository for the demo application ($APP_NAME)"
prtText ""
execCmd "cd $TDHHOME/scripts && ./tap-create-gitea-repository.sh tap $APP_NAME"

prtHead "Create a local Git Repository for ($APP_NAME)"
execCmd "unzip /tmp/${APP_NAME}.zip -d /tmp"
cd /tmp/$APP_NAME
slntCmd "cd /tmp/$APP_NAME"
execCmd "git init"
slntCmd "git config user.email \"cody@tea.com\""
slntCmd "git config user.name \"cody\""
execCmd "cat .git/config"
slntCmd "git add ."
execCmd "git commit -m \"first commit\""

export GIT_USERNAME=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_USER)
export GIT_PASSWORD=$(getConfigMap tanzu-demo-hub TDH_SERVICE_GITEA_ADMIN_PASS)

# --- INITIAL CREDENTIAL HELPER SCRIPT ---
$TDHHOME/scripts/git-credentials-helper.sh --install

prtHead "Push local Git Repository ($APP_NAME) to Gitea"
slntCmd "git remote add origin http://gitea.$DOMAIN/tap/${APP_NAME}.git"
execCmd "git push -u origin master"

exit

prtHead "Login to the vSphere Supervisor Cluster ($VSPHERE_TKGS_SUPERVISOR_CLUSTER) and set Environment and Context"
execCmd "kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER -u $VSPHERE_TKGS_VCENTER_ADMIN"
execCmd "kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER"


prtHead "Configure Cloud Config"
prtText "Documentation: https://cloudinit.readthedocs.io"
execCat "files/vmsvc-centos-cloud-config.yaml"
prtText "encoded=\$(cat files/vmsvc-centos-cloud-config.yaml | base64)"
encoded=$(cat files/vmsvc-centos-cloud-config.yaml | base64 --wrap=1000)

execCmd "echo \$encoded"

net=$(kubectl -n tanzu-demo-hub get network -o json | jq -r '.items[].metadata.name') 

cat files/vmsvc-centos-vm.yaml | sed \
  -e "s/VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS/$VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS/g" \
  -e "s/VSPHERE_TKGS_NETWORK_NAME/$net/g" > /tmp/vmsvc-centos-vm.yaml
echo "  user-data: >-" >> /tmp/vmsvc-centos-vm.yaml
echo "    $encoded" >> /tmp/vmsvc-centos-vm.yaml

prtText ""
prtHead "Create Virtual Machine (vmsvc-centos-vm)"
execCat "/tmp/vmsvc-centos-vm.yaml"
execCmd "kubectl apply -f /tmp/vmsvc-centos-vm.yaml  --wait=true"

vmip=""
while [ "$vmip" == "" -o "$vmip" == "null" ]; do
  vmip=$(kubectl -n tanzu-demo-hub get virtualmachine vmsvc-centos-vm -o json | jq -r '.status.vmIp' 2>/dev/null)
  sleep 5
done

execCmd "kubectl get VirtualMachine -A -o wide"
execCmd "kubectl -n tanzu-demo-hub describe virtualmachine vmsvc-centos-vm"

ssh-keygen -f "/home/tanzu/.ssh/known_hosts" -R "$vmip" > /dev/null 2>&1
prtHead "Access the Virtual Machine (User: vmware, Pawword: Admin!23)"
prtText "ssh -o StrictHostKeyChecking=no vmware@$vmip"

prtText ""
echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"
exit



Creating a new repository on the command line
git init
git add .
git commit -m "first commit"
git remote add origin http://gitea.apps-contour.vsptap.pcfsdu.com/tap/weatherforecast-steeltoe.git
git push -u origin master



