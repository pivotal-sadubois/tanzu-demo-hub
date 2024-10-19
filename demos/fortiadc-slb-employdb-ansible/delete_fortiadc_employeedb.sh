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
export LOCK_FILE_1=$HOME/.tdh/deploy_fortiadc_employeedb.lock
export LOCK_FILE_2=$HOME/.tdh/deploy_fortiadc_employeedb-ssl.lock

# --- SETTING FOR TDH-TOOLS ---
export NATIVE=0                ## NATIVE=1 r(un on local host), NATIVE=0 (run within docker)
export START_COMMAND="$*"
export CMD_EXEC=$(basename $0)
export CMD_ARGS=$*
export TMPDIR=/tmp

if [ -f $LOCK_FILE_2 ]; then 
  echo "ERROR: The deployment (deploy_fortiadc_employeedb-ssl) is still active, please cleen this up first."
  echo "       => ./deploy_fortiadc_employeedb-ssl.sh"
  exit
fi

[ -f $HOME/.tanzu-demo-hub.cfg ] && . $HOME/.tanzu-demo-hub.cfg
[ -f $TDHHOME/functions ] && . $TDHHOME/functions
[ -f $HOME/PythonDev/bin/activate ] && source $HOME/PythonDev/bin/activate

# --- VERIFY COMMAND LINE ARGUMENTS ---
checkCLIarguments $*

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
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

prtHead "To delete the configuaration we need to create a removal Playbook to cleanup the configuration"
execCat "$TMPDIR/fortiadc-lb-delete.yml"

prtHead "Delete the Server Load Balancer with the Ansible Playbook"
echo -e "     => ansible-playbook /tmp/fortiadc-lb-delete.yml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}.yml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-delete.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}.yml" \
  --vault-password-file $HOME/.ansible/vault_password | python3 scripts/indent_output.py; ret=$?

prtHead "Deleting kubernetes deployment of äAPPNAME"
for n in 01 02 03; do
  kubectl -n $NAMESPACE delete svc ${APPNAME}-$n > /dev/null 2>&1
  kubectl -n $NAMESPACE delete deployment ${APPNAME}-$n > /dev/null 2>&1
  kubectl wait --for=delete pod -l app=${APPNAME}-$n -n $NAMESPACE --timeout=300s > /dev/null 2>&1
done
kubectl delete ns $NAMESPACE > /dev/null 2>&1

if [ $ret -ne 0 ]; then
  echo "ERROR: The ansible playbook failed to remove the deployment, please fix the error and start over"
  exit
else
  rm -f $LOCK_FILE_1
fi

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

exit
