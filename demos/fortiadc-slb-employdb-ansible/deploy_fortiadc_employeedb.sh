#!/bin/bash
# ============================================================================================
# File: ........: deploy_fortiadc_employeedb
# Demo Package .: fortiadc-slb-employdb-ansible
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
export VS_IP_ADDRESS=10.0.101.52
export EMPLOYEEDB_DOCKER_IMAGE=sadubois/employeedb:1.1.0
export LOCK_FILE=$HOME/.tdh/deploy_fortiadc_employeedb.lock

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*
export TMPDIR=/tmp

genTraffic() {
  st1=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-01 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  st2=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-02 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  st3=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-03 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")

  messageLineIntendDemos
  ls1=0; ls2=0; ls3=0; cnt=1
  while [ $cnt -le 10 ]; do
    curl http://$VS_IP_ADDRESS/actuator/health > /dev/null 2>&1
    cn1=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-01 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
    cn2=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-02 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
    cn3=$(kubectl -n $NAMESPACE logs $(kubectl -n $NAMESPACE get pods -l app=${APPNAME}-03 --no-headers -o custom-columns=":metadata.name") | grep -c "GET \"/actuator")
  
    let tt1=cn1-st1
    let tt2=cn2-st2
    let tt3=cn3-st3
  
    tx1=$(printf "%02d\n" $tt1)
    tx2=$(printf "%02d\n" $tt2)
    tx3=$(printf "%02d\n" $tt3)
    hdr=$(printf "%03d\n" $cnt)
  
    [ $tt1 -eq $ls1 ] && tx1="${ip1} [${tx1}]" || tx1="\033[32m${ip1} [${tx1}]\033[0m"
    [ $tt2 -eq $ls2 ] && tx2="${ip2} [${tx2}]" || tx2="\033[32m${ip2} [${tx2}]\033[0m"
    [ $tt3 -eq $ls3 ] && tx3="${ip3} [${tx3}]" || tx3="\033[32m${ip3} [${tx3}]\033[0m"
  
    b=$(printf "%02d\n" $ttb)
    g=$(printf "%02d\n" $ttg)
  
    echo -e "     [${hdr}] http://employeedb-slb.fortidemo.ch/actuator/health                       $tx1   $tx2   $tx3"
  
    ls1=$tt1; ls2=$tt2; ls3=$tt3
    let cnt=cnt+1
    sleep 2
  done
  messageLineIntendDemos
  emptyLine
}

if [ -f $LOCK_FILE ]; then 
  echo ""
  echo "ERROR: Demo is already deployed, please make a cleanup first"
  echo "       => ./delete_fortiadc_employeedb.sh"
  echo ""
  exit
fi

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/PythonDev/bin/activate ] && source $HOME/PythonDev/bin/activate

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '
echo '                             _____          _   _    _    ____   ____                 '
echo '                            |  ___|__  _ __| |_(_)  / \  |  _ \ / ___|                '
echo '                            | |_ / _ \|  __| __| | / _ \ | | | | |                    '
echo '                            |  _| (_) | |  | |_| |/ ___ \| |_| | |___                 '
echo '                            |_|  \___/|_|   \__|_/_/   \_\____/ \____|                '
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
  emptyLine
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
    echo -e "     => kubectl create deployment ${APPNAME}-$n --image=$EMPLOYEEDB_DOCKER_IMAGE --port=$APPPORT -n $NAMESPACE\c\b"; read x
    cat files/deployment.yml | sed -e "s+XXXDOCKERXXX+$EMPLOYEEDB_DOCKER_IMAGE+g" -e "s/XXX/${APPNAME}-$n/g" > /tmp/deployment_${APPNAME}-$n.yml
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
  emptyLine
  prtHead "Deploy the $APPNAME application in the kubernetes namespace $NAMESPACE"
  prtText " ▪ Create kubernetes namespace $NAMESPACE"
  kubectl create namespace $NAMESPACE > /dev/null 2>&1
  kubectl -n $NAMESPACE label --overwrite ns $NAMESPACE pod-security.kubernetes.io/enforce=privileged > /dev/null 2>&1
  dockerPullSecret $NAMESPACE > /dev/null 2>&1
  kubectl create secret generic mysql-credentials \
        --from-literal=spring.datasource.username=bitnami \
        --from-literal=spring.datasource.password=bitnami \
        --namespace $NAMESPACE > /dev/null 2>&1

  prtText " ▪ Deploy the $APPNAME application (${APPNAME}-01, ${APPNAME}-02 and ${APPNAME}-03)"
  for n in 01 02 03; do
    cat files/deployment.yml | sed -e "s+XXXDOCKERXXX+$EMPLOYEEDB_DOCKER_IMAGE+g" -e "s/XXX/${APPNAME}-$n/g" > /tmp/deployment_${APPNAME}-$n.yml
    kubectl -n employeedb apply -f /tmp/deployment_${APPNAME}-$n.yml > /dev/null 2>&1
    kubectl wait --for=condition=Ready pod -l app=${APPNAME}-$n -n $NAMESPACE --timeout=300s > /dev/null 2>&1
  done
  
  prtText " ▪ Expose Kubernetes Service on Port 8080"
  for n in 01 02 03; do
    kubectl expose deployment ${APPNAME}-$n --port=$APPPORT --type=LoadBalancer -n $NAMESPACE > /dev/null 2>&1
    sleep 1
  done
  sleep 8
  emptyLine
fi

ip1=$(kubectl -n $NAMESPACE get service/${APPNAME}-01 -o json | jq -r '.status.loadBalancer.ingress[].ip') 
ip2=$(kubectl -n $NAMESPACE get service/${APPNAME}-02 -o json | jq -r '.status.loadBalancer.ingress[].ip') 
ip3=$(kubectl -n $NAMESPACE get service/${APPNAME}-03 -o json | jq -r '.status.loadBalancer.ingress[].ip') 

prtText "Open WebBrowser and verify the deployment"
echo "     => http://$ip1:$APPPORT"
echo "     => http://$ip2:$APPPORT"
echo "     => http://$ip3:$APPPORT"
echo ""
echo -e "     Press 'return' to continue \c\b"; read x
echo ""

prtHead "Create a Ansible Playbook"
prtText "The Playbook creates a Virtual Server, Real Server Pool with four Members. We create at first a values file"
prtText "and add the IP adresses of the four applications as Real Server Pool"

wt1=1; wt2=1; wt3=1
cat playbook/fortiadc-lb-vars-${APPNAME}.yml | sed \
  -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
  -e "s/XXXIP3XXX/${ip3}/g" -e "s/YYY1YYY/${wt1}/g" \
  -e "s/YYY2YYY/${wt2}/g" -e "s/YYY3YYY/${wt3}/g" \
  > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yml 

execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yml"

prtHead "Create a protected ansible-vault password in your home directory"
echo -e  "     => echo \"my-secret-vault-password\" > \$HOME/.ansible/vault_password\c\b"; read x
echo -e  "     => chmod 700 \$HOME/.ansible/vault_password\c\b"; read x
execCmd "ls -la \$HOME/.ansible/vault_password"

#prtText "Encrypt credentials with ansible-vault"
prtText "Create a vault file containing the 'fortiadc_password' password in clear text"

echo "# vault.yml"                              >  $TMPDIR/vault.yml 
echo "fortiadc_password: \"Password12345\""     >> $TMPDIR/vault.yml
execCat "$TMPDIR/vault.yml"

prtText "Encrypt the vault.yml with ansible-vault"
slntCmd "ansible-vault encrypt /tmp/vault.yml --vault-password-file \$HOME/.ansible/vault_password"
messageLineIntendDemos
echo "     Encryption successful"
messageLineIntendDemos
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
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-config.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
 --vault-password-file $HOME/.ansible/vault_password | python scripts/indent_output.py

prtHead "Now let's test the new Virtual Server"
prtText "Open WebBrowser and verify the deployment"
echo "     => http://10.0.101.52"
echo "     => http://employeedb-slb.fortidemo.ch"
echo ""

#########################################################################################################################
###################### TEST: Demonstration how load is spread across real server pool members ###########################
#########################################################################################################################
ret=$(askQustion "Would you like to see how the Load Balancer is spreading traffic across the instances ? <y/n>:")
[ "$ret" == "y" ] && genTraffic

#########################################################################################################################
############################## TEST: change weight assigned to a real server pool member ################################
#########################################################################################################################
ret=$(askQustion "Would you like to see how different weighting changes the balancing behaviour ? <y/n>:")
if [ "$ret" == "y" ]; then 
  wt1=1; wt2=3; wt3=5
  cat playbook/fortiadc-lb-vars-${APPNAME}.yml | sed \
    -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
    -e "s/XXXIP3XXX/${ip3}/g" -e "s/YYY1YYY/${wt1}/g" \
    -e "s/YYY2YYY/${wt2}/g" -e "s/YYY3YYY/${wt3}/g" \
    > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yml

  emptyLine
  prtText "We are going to modify the configuration that eacht Member gets the following traffic weighing (Member-1: $wt1, Member-2, $wt2 and Member-3: $wt3)"
  execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yml"

  prtText "To only update the Real Server Pool Members, we create an Real Server Pool Member Ansible Playbook"
  cp playbook/fortiadc-lb-member-update.yml /tmp

  execCat "$TMPDIR/fortiadc-lb-member-update.yml"

  prtText "Configure the Server Load Balancer with the Ansible Playbook"
  echo -e "     => ansible-playbook $TMPDIR/fortiadc-lb-member-update.yml \\"
  echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
  echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
  messageLineIntendDemos

  ansible-playbook $TMPDIR/fortiadc-lb-member-update.yml \
    -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
   --vault-password-file $HOME/.ansible/vault_password | python scripts/indent_output.py
  
  prtText "Let's generate again some traffic and watch the balancing"

  genTraffic
fi

#########################################################################################################################
################################ TEST: How Load is spreading with one disabled Member ###################################
#########################################################################################################################
ret=$(askQustion "Would you like to see what happens when we disable a link ? <y/n>:")
if [ "$ret" == "y" ]; then
  wt1=1; wt2=1; wt3=1
  cat playbook/fortiadc-lb-vars-${APPNAME}.yml | sed \
    -e '/name: rs_employeedb_2/,/weight: YYY2YYY/ s/status: enable/status: disable/g' \
    -e "s/XXXIP1XXX/${ip1}/g" -e "s/XXXIP2XXX/${ip2}/g" \
    -e "s/XXXIP3XXX/${ip3}/g" -e "s/YYY1YYY/${wt1}/g" \
    -e "s/YYY2YYY/${wt2}/g" -e "s/YYY3YYY/${wt3}/g" \
    > $TMPDIR/fortiadc-lb-vars-${APPNAME}.yml
    
  emptyLine
  prtText "We are going to modify the configuration that eacht Member gets the following traffic weighing (Member-1: $wt1, Member-2, $wt2 and Member-3: $wt3)"
  execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}.yml"
    
  prtText "To only update the Real Server Pool Members, we create an Real Server Pool Member Ansible Playbook"
  cp playbook/fortiadc-lb-member-update.yml /tmp
    
  execCat "$TMPDIR/fortiadc-lb-member-update.yml"
    
  prtText "Configure the Server Load Balancer with the Ansible Playbook"
  echo -e "     => ansible-playbook $TMPDIR/fortiadc-lb-member-update.yml \\"
  echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
  echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
  messageLineIntendDemos

  ansible-playbook $TMPDIR/fortiadc-lb-member-update.yml \
    -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
   --vault-password-file $HOME/.ansible/vault_password | python scripts/indent_output.py
  
  prtText "Let's generate again some traffic and watch the balancing"

  genTraffic
fi

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

echo "$(date)" > $LOCK_FILE
  
exit


emptyLine
prtHead "The Demo is finish, let's do some cleanup and create the removal Playbook to cleanup the configuration"
execCat "$TMPDIR/fortiadc-lb-delete.yml"

prtHead "Delete the Server Load Balancer with the Ansible Playbook"
echo -e "     => ansible-playbook /tmp/fortiadc-lb-delete.yml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-delete.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
  --vault-password-file $HOME/.ansible/vault_password | python3 scripts/indent_output.py

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

exit


# curl http://10.0.101.51:3838   		=> 10.0.101.123 [01]  10.0.101.123 [01] 10.0.101.123 [01] 10.0.101.123 [01]




