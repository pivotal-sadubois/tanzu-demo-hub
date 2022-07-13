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
echo '           _____ _  ______    __                     ____        _                    '
echo '          |_   _| |/ / ___|  / _| ___  _ __  __   __/ ___| _ __ | |__   ___ _ __ ___  '
echo '            | | |   / |  _  | |_ / _ \|  __| \ \ / /\___ \|  _ \|  _ \ / _ \  __/ _ \ '
echo '            | | | . \ |_| | |  _| (_) | |     \ V /  ___) | |_) | | | |  __/ | |  __/ '
echo '            |_| |_|\_\____| |_|  \___/|_|      \_/  |____/| .__/|_| |_|\___|_|  \___| '
echo '                                                          |_|                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '               VMware vSphere for Tanzu Service - Deploy Virtual Machine              '  
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

if [ "$VSPHERE_TKGS_VCENTER_SERVER" == "" -o "$VSPHERE_TKGS_VCENTER_ADMIN" == "" -o "$VSPHERE_TKGS_VCENTER_PASSWORD" == "" ]; then 
  echo "ERROR: Please provide vSphere Cluster credentionals in $HOME/.tanzu-demo-hub.cfg : "
  echo "         export VSPHERE_TKGS_VCENTER_SERVER=wcp.haas-XYZ.pez.vmware.com"
  echo "         export VSPHERE_TKGS_VCENTER_ADMIN=administrator@vsphere.local"
  echo "         export VSPHERE_TKGS_VCENTER_PASSWORD=<password>"
  echo "         export VSPHERE_TKGS_SUPERVISOR_CLUSTER=wcp.haas-490.pez.vmware.com"
  exit 1
fi

# --- VERIFY SUPERVISOR CLUSTER LOGIN --- 
export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_TKGS_VCENTER_PASSWORD
kubectl vsphere login --insecure-skip-tls-verify --server $VSPHERE_TKGS_SUPERVISOR_CLUSTER -u $VSPHERE_TKGS_VCENTER_ADMIN > /dev/null 2>&1
if [ $? -ne 0 ]; then 
  echo "ERROR: can not login to vSphere Supervisor Cluster: $VSPHERE_TKGS_VCENTER_SERVER"
fi

# --- SET ENVIRONMENT ---
[ "$VSPHERE_NAMESPACE" == "" ] && export VSPHERE_NAMESPACE=tanzu-demo-hub

# --- CLEANUP ---
cmdLoop kubectl config use-context $VSPHERE_TKGS_SUPERVISOR_CLUSTER > /dev/null 2>&1
#cmdLoop kubectl get tanzukubernetescluster -n $VSPHERE_NAMESPACE -o json > /tmp/output.json 
#nam=$(jq -r --arg key "$GUEST_CLUSTER" '.items[] | select(.metadata.name == $key).metadata.name' /tmp/output.json)
#if [ "$nam" == "$GUEST_CLUSTER" ]; then 
#  echo " INFO: Deleting leftover TKG Cluster ($GUEST_CLUSTER) from previous demo. This"
#  echo "       may take a couple of minues."
#  echo ""
#  cmdLoop kubectl delete tanzukubernetescluster -n $VSPHERE_NAMESPACE $GUEST_CLUSTER --wait=true > /dev/null 2>&1
#fi

prtHead "Login to the vSphere Envifonment on (http://$VSPHERE_TKGS_VCENTER_SERVER / $VSPHERE_TKGS_VCENTER_ADMIN)" 
prtText " - inspect 'Hosts and Clusters'"
prtText " - inspect 'Workload Management'"
prtText ""
prtText "press 'return' to continue"; read x

prtHead "Create a new vSphere Namespace '$VSPHERE_NAMESPACE'"
prtText " - Menu -> 'Workload Management' => New Namespace"
prtText "      - Name: $VSPHERE_NAMESPACE => Create"
prtText " - Namespace -> '$VSPHERE_NAMESPACE' -> Summary"
#prtText "      - Storage -> Add Storage -> $VSPHERE_TKGS_SUPERVISOR_STORAGE_POLICPOLICY"
prtText "      - Storage -> Add Storage -> $VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS"
prtText "      - Permissions"
prtText "      - Capacity and Usage"
prtText "      - VM Servic -> Add VM Class"
prtText "           best-effort-medium, guaranteed-medium"
prtText ""
prtText "press 'return' to continue"; read x


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
