#!/bin/bash
# ============================================================================================
# File: ........: fortiadc-slb-ansible
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# --------------------------------------------------------------------------------------------
# Category .....: VMware Tanzu Data for Postgres
# Description ..: Database Resize (CPU, Memory and Disk) 
# ============================================================================================
# https://postgres-kubernetes.docs.pivotal.io/1-1/update-instances.html

export APPNAME="employeedb"
export APPPORT="8080"
export TDH_DEMO_DIR="fortiadc-slb-employdb-ansible"
export TDHHOME=$(echo -e "$(pwd)\n$(dirname $0)" | grep "tanzu-demo-hub" | head -1 | sed "s+\(^.*tanzu-demo-hub\).*+\1+g")
export TDHDEMO=$TDHHOME/demos/$TDH_DEMO_DIR
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export NAMESPACE=${APPNAME}

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*
export TMPDIR=/tmp

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/PythonDev/bin/activate ] && source $HOME/PythonDev/bin/activate

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '                              _____          _   _            _                       '
echo '                             |  ___|__  _ __| |_(_)_ __   ___| |_                     '
echo '                             | |_ / _ \|  __| __| |  _ \ / _ \ __|                    '
echo '                             |  _| (_) | |  | |_| | | | |  __/ |_                     '
echo '                             |_|  \___/|_|   \__|_|_| |_|\___|\__|                    '
echo '                                                                                      '
echo '                    _              _ _     _        ____                              '
echo '                   / \   _ __  ___(_) |__ | | ___  |  _ \  ___ _ __ ___   ___         '
echo '                  / _ \ |  _ \/ __| |  _ \| |/ _ \ | | | |/ _ \  _   _ \ / _ \        '
echo '                 / ___ \| | | \__ \ | |_) | |  __/ | |_| |  __/ | | | | | (_) |       '
echo '                /_/   \_\_| |_|___/_|_.__/|_|\___| |____/ \___|_| |_| |_|\___/        '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '             Configure an Server Loadbalancer on a FortiADC with Ansible Playbook     '
echo '                                  by Sacha Dubois, Fprtinet Inc                       '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

#TDH_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_DOMAIN)
#TDH_ENVNAME=$(getConfigMap tanzu-demo-hub TDH_ENVNAME)
#TDH_INGRESS_CONTOUR_LB_DOMAIN=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_DOMAIN)
#TDH_INGRESS_CONTOUR_LB_IP=$(getConfigMap tanzu-demo-hub TDH_INGRESS_CONTOUR_LB_IP)
#TDH_LB_NGINX=$(getConfigMap tanzu-demo-hub TDH_LB_NGINX)
#DOMAIN=${TDH_INGRESS_CONTOUR_LB_DOMAIN}

if [ 2 -eq 1 ]; then 
# Cleanup
for n in 01 02 03; do
  kubectl -n $NAMESPACE delete svc ${APPNAME}-$n > /dev/null 2>&1
  kubectl -n $NAMESPACE delete deployment ${APPNAME}-$n > /dev/null 2>&1
  kubectl wait --for=delete pod -l app=${APPNAME}-$n -n $NAMESPACE --timeout=300s > /dev/null 2>&1
done
kubectl delete ns $NAMESPACE > /dev/null 2>&1

echo "This demo requires that four instances of our app '$APPNAME' are deployed on the" 
echo "kubernetes cluster in order to use the FortiADC Server Load Balancer. You can choose if" 
echo "like to see these steps in details or we automaticly set it out in the background. "

echo ""
answer=""
while [ "$answer" != "y" -a "$answer" != "n" ]; do
  echo -e "Would you like to see the deployment steps ? <y/n> : \c\b"; read answer
done

if [ "$answer" == "y" ]; then 
  echo ""
  prtHead "Create the application namespace for $APPNAME"
  execCmd "kubectl create namespace $NAMESPACE"

  kubectl create namespace $NAMESPACE > /dev/null 2>&1
  kubectl -n $NAMESPACE label --overwrite ns $NAMESPACE pod-security.kubernetes.io/enforce=privileged > /dev/null 2>&1
  dockerPullSecret $NAMESPACE > /dev/null 2>&1
  kubectl create secret generic mysql-credentials \
        --from-literal=spring.datasource.username=bitnami \
        --from-literal=spring.datasource.password=bitnami \
        --namespace $NAMESPACE > /dev/null 2>&1

  prtHead "Deploy the $APPNAME application instances"
  for n in 01 02 03; do
    echo -e "     => kubectl create deployment ${APPNAME}-$n --image=sadubois/employeedb:1.0.0 --port=$APPPORT -n $NAMESPACE\c\b"; read x
    cat files/deployment.yml | sed "s/XXX/${APPNAME}-$n/g" > /tmp/deployment_${APPNAME}-$n.yml
    kubectl -n employeedb apply -f /tmp/deployment_${APPNAME}-$n.yml > /dev/null 2>&1
    kubectl wait --for=condition=Ready pod -l app=${APPNAME}-$n -n $NAMESPACE --timeout=300s > /dev/null 2>&1
  done

  execCmd "kubectl get pods -n $NAMESPACE"

  prtHead "Expose the Service type LoadBalancer"
  for n in 01 02 03; do
    echo -e "     => kubectl expose deployment ${APPNAME}-$n --port=$APPPORT --type=LoadBalancer -n $NAMESPACE\c\b"; read x
    kubectl expose deployment ${APPNAME}-$n --port=$APPPORT --type=LoadBalancer -n $NAMESPACE > /dev/null 2>&1
    sleep 1
  done
  sleep 2

  execCmd "kubectl get pods,svc -n $NAMESPACE"
else
  for n in 01 02 03; do
    kubectl create namespace $n > /dev/null 2>&1
    dockerPullSecret $n > /dev/null 2>&1
  done
fi
fi

ip1=$(kubectl -n $NAMESPACE get service/${APPNAME}-01 -o json | jq -r '.status.loadBalancer.ingress[].ip') 
ip2=$(kubectl -n $NAMESPACE get service/${APPNAME}-02 -o json | jq -r '.status.loadBalancer.ingress[].ip') 
ip3=$(kubectl -n $NAMESPACE get service/${APPNAME}-03 -o json | jq -r '.status.loadBalancer.ingress[].ip') 

prtHead "Open WebBrowser and verify the deployment"
echo "     => http://$ip1:$APPPORT"
echo "     => http://$ip2:$APPPORT"
echo "     => http://$ip3:$APPPORT"
echo ""

prtHead "Create a Ansible Playbook"
prtText "The Playbook creates a Virtual Server, Real Server Pool with four Members"
prtText ""

prtHead "Prepare the Ansible Playbook values file to setup the FortiADC Server Loadbalancer"
prtText "We will add the IP adresses of the four applications as Real Server Pool"

cat playbook/fortiadc-lb-vars-${APPNAME}.yml | sed -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
  -e "s/XXXIP3XXX/${ip3}/g" -e "s/XXXIP4XXX/${ip4}/g" > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yml 

execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yml"

prtHead "Create a protected ansible-vault password in your home directory"
echo -e  "     echo \"my-secret-vault-password\" > \$HOME/.ansible/vault_password\c\b"; read x
echo -e  "     chmod 700 \$HOME/.ansible/vault_password\c\b"; read x
echo ""

prtHead "Encrypt credentials with ansible-vault"
prtText "Create a vault file containing the 'fortiadc_password' password in clear text"

echo "# vault.yml"                              >  $TMPDIR/vault.yml 
echo "fortiadc_password: \"Password12345\""     >> $TMPDIR/vault.yml
execCat "$TMPDIR/vault.yml"

prtText "Encrypt the vault.yml with ansible-vault"
slntCmd "ansible-vault encrypt /tmp/vault.yml --vault-password-file \$HOME/.ansible/vault_password"
echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo "     Encryption successful"
echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo ""

execCat "$TMPDIR/vault.yml"

prtHead "Create an Inventory file for the target hosts and credentials"
prtText "We are using the encrypted 'fortiadc_password' we have just created in the /tmp/vault.yml"
cp playbook/inventory /tmp
execCat "$TMPDIR/inventory"

prtHead "Let's create the Playbook the creates the Virtual Server, Real Server Pools and Members"
cp playbook/fortiadc-lb-config.yml /tmp
cp playbook/fortiadc-lb-delete.yml /tmp
execCat "$TMPDIR/fortiadc-lb-config.yml"

prtHead "Configure the Server Load Balancer with the Ansible Playbook"
echo -e "     => ansible-playbook /tmp/fortiadc-lb-config.yml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"

ansible-playbook /tmp/fortiadc-lb-config.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
 --vault-password-file $HOME/.ansible/vault_password | python scripts/indent_output.py

prtHead "Now let's test the new Virtual Server"
prtText "Open WebBrowser and verify the deployment"
echo "     => http://10.0.101.52"
echo "     => http://employdb-slb.fortidemo.ch"
echo ""

prtHead "Let's create the removal Playbook to cleanup the configuration"
execCat "$TMPDIR/fortiadc-lb-delete.yml"

prtHead "Delete the Server Load Balancer with the Ansible Playbook"
echo -e "     => ansible-playbook /tmp/fortiadc-lb-delete.yml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
echo "     -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"

ansible-playbook /tmp/fortiadc-lb-delete.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
  --vault-password-file $HOME/.ansible/vault_password | python3 scripts/indent_output.py

echo "     -----------------------------------------------------------------------------------------------------------"
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
echo "     -----------------------------------------------------------------------------------------------------------"

exit


# curl http://10.0.101.51:3838   		=> 10.0.101.123 [01]  10.0.101.123 [01] 10.0.101.123 [01] 10.0.101.123 [01]




