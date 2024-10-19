#!/bin/bash
# ============================================================================================
# File: ........: deploy_fortiadc_employeedb_ssl
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
export LOCK_FILE=$HOME/.tdh/deploy_fortiadc_employeedb-ssl.lock

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

CERTDIR=$HOME/workspace/certbot/letsencrypt/etc/live
EMPLOYEEDB_CERTIFICATE=$CERTDIR/employeedb.fortidemo.ch/fullchain.pem
EMPLOYEEDB_PROVATE_KEY=$CERTDIR/employeedb.fortidemo.ch/privkey.pem

# Extract notBefore and notAfter dates
not_before=$(openssl x509 -in $EMPLOYEEDB_CERTIFICATE -noout -dates | grep 'notBefore=' | cut -d'=' -f2)
not_after=$(openssl x509 -in $EMPLOYEEDB_CERTIFICATE -noout -dates | grep 'notAfter=' | cut -d'=' -f2)

# Convert to Unix time
not_before_unix=$(date -j -f "%b %d %T %Y %Z" "$not_before" +"%s")
not_after_unix=$(date -j -f "%b %d %T %Y %Z" "$not_after" +"%s")

current_time=$(date +%s)
if [ "$not_after_unix" -lt "$current_time" ]; then
    echo "ERROR: The SSL/TLS Certificate for employeedb.fortidemo.sh) has expired."
    echo "       Please regenerate the Certificate:"
    echo "       => cd $HOME/workspace/certbot"
    echo "       => ./genCertificate_employeedb_fortidemo.sh"
    exit
fi

prtHead "Let's create an Ansible Playbook to configure SSL/TLS on the Virtual Server"
prtText "At first, we create a variable file again"

wt1=1; wt2=1; wt3=1
cat playbook/fortiadc-lb-vars-${APPNAME}-ssl.yml | sed \
  -e "s+XXX1XXX+${EMPLOYEEDB_CERTIFICATE}+g" -e "s+XXX2XXX+${EMPLOYEEDB_PROVATE_KEY}+g" \
  > $TMPDIR/fortiadc-lb-vars-${APPNAME}-ssl.yml 

execCat "$TMPDIR/fortiadc-lb-vars-${APPNAME}-ssl.yml"

cp playbook/fortiadc-lb-config-ssl.yml /tmp
cp playbook/fortiadc-lb-delete-ssl.yml /tmp
execCat "$TMPDIR/fortiadc-lb-config-ssl.yml"

prtHead "Run the Ansible Playbook (/tmp/fortiadc-lb-config-ssl.yml)"
prtText "The Playbook creates am Virtual Server (employeedb-ssl) for TLS/SSL. Therefor we need to create a"
prtText "Client SSL Profile containing the Certificate with a Cert Group and a local Certificate."
echo -e "     => ansible-playbook /tmp/fortiadc-lb-config-ssl.yml \\"
echo -e "          -i /tmp/inventory --extra-vars \"@/tmp/fortiadc-lb-vars-${APPNAME}-ssl.yml\" \\"
echo -e "          --vault-password-file $HOME/.ansible/vault_password\c\b"; read x
messageLineIntendDemos

ansible-playbook /tmp/fortiadc-lb-config-ssl.yml \
  -i /tmp/inventory --extra-vars "@/tmp/fortiadc-lb-vars-${APPNAME}-ssl.yml" \
 --vault-password-file $HOME/.ansible/vault_password -v 2>/dev/null | python scripts/indent_output.py

prtHead "Now let's test the new Virtual Server"
prtText "Open WebBrowser and verify the deployment"
echo "     => https://employeedb-slb.fortidemo.ch"
echo ""

messageLineIntendDemos
echo "                                             * --- END OF THE DEMO --- *"
echo "                                                THANKS FOR ATTENDING"
messageLineIntendDemos

echo "$(date)" > $LOCK_FILE
  
exit
