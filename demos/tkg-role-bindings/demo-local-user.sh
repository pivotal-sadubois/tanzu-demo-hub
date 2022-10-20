#!/bin/bash
# ============================================================================================
# File: ........: demo-local-user.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Description ..: Deploy a Virtual Machine trough vm-service
# Example ......: https://cloudinit.readthedocs.io/en/latest/topics/examples.html
# ============================================================================================
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Need to run within a tdh-tools container" && exit

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
echo '                   ____       _        ____  _           _ _                          '
echo '                  |  _ \ ___ | | ___  | __ )(_)_ __   __| (_)_ __   __ _ ___          '
echo '                  | |_) / _ \| |/ _ \ |  _ \| |  _ \ / _` | |  _ \ / _  / __|         '
echo '                  |  _ < (_) | |  __/ | |_) | | | | | (_| | | | | | (_| \__ \         '
echo '                  |_| \_\___/|_|\___| |____/|_|_| |_|\__,_|_|_| |_|\__, |___/         '
echo '                                                                   |___/              '
echo '                                 ____                                                 '
echo '                                |  _ \  ___ _ __ ___   ___                            '
echo '                                | | | |/ _ \  _   _ \ / _ \                           '
echo '                                | |_| |  __/ | | | | | (_) |                          '
echo '                                |____/ \___|_| |_| |_|\___/                           '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                       Role Binding - Allow Privileged Containers                     '
echo '                               by Sacha Dubois, VMware Inc                            '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '



user=user1

# --- CLEANUP ---
kubectl delete rolebinding developer-binding-$user  > /dev/null 2>&1
kubectl delete role developer > /dev/null 2>&1
kubectl delete csr $user > /dev/null 2>&1

prtHead "To authenticate to Kubernetes API as 'Normal User' a X509 Client Certificate is requred"
prtText " - Create private key"
prtText " - Create CertificateSigningRequest"
prtText ""
execCmd "openssl genrsa -out /tmp/${user}.key 2048"
execCmd "openssl req -new -key /tmp/${user}.key -out /tmp/${user}.csr -subj \"/CN=${user}/O=group1/O=group2\""

prtHead "Create a CertificateSigningRequest"
prtText " - Create a CertificateSigningRequest and submit it to a Kubernetes Cluster via kubectl"
prtText ""

pki=$(cat /tmp/${user}.csr | base64 | tr -d "\n")

echo "apiVersion: certificates.k8s.io/v1"                                   >  /tmp/csr.yaml
echo "kind: CertificateSigningRequest"                                      >> /tmp/csr.yaml
echo "metadata:"                                                            >> /tmp/csr.yaml
echo "  name: $user"                                                        >> /tmp/csr.yaml
echo "spec:"                                                                >> /tmp/csr.yaml
echo "  request: $pki"                                                      >> /tmp/csr.yaml
echo "  signerName: kubernetes.io/kube-apiserver-client"                    >> /tmp/csr.yaml
echo "  usages: ['digital signature', 'key encipherment', 'client auth']"   >> /tmp/csr.yaml

execCat /tmp/csr.yaml  
execCmd "kubectl apply -f /tmp/csr.yaml"
execCmd "kubectl get csr"

prtHead "The Kubernetes Administrator needs to Approve or Deny the CSR request"
execCmd "kubectl certificate approve $user"

prtHead "Retreive the Certificate"
prtText " - The certificate value is in Base64-encoded format under status.certificate."
prtText ""
execCmd "kubectl get csr/$user -o yaml"
execCmd "kubectl get csr $user -o jsonpath='{.status.certificate}'| base64 -d > /tmp/${user}.crt"

prtHead "Create Role and RoleBinding for the User"
prtText " - create a Role 'developer' for the user $user"
prtText " - create a RoleBinding for basic commands"
prtText ""
execCmd "kubectl create role developer --verb=create --verb=get --verb=list --verb=update --verb=delete --resource=pods --resource=services"
execCmd "kubectl create rolebinding developer-binding-$user --role=developer --user=$user"

prtHead "Test API Access for user $user"
execCmd "kubectl --client-key=/tmp/${user}.key --client-certificate=/tmp/${user}.crt get pods"
execCmd "kubectl --client-key=/tmp/${user}.key --client-certificate=/tmp/${user}.crt get replicationcontrollers,deployments.apps,ns"
prtText "We only have a RoleBinding for pods ans service, therefor we get an error accessing other objects"

prtText ""
echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"
exit
