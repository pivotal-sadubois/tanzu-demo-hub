# ============================================================================================
# File: ........: deploy_demo_tls.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Monitoring with Grafana and Prometheus Demo
# ============================================================================================

BASENAME=$(basename $0)
DIRNAME=$(dirname $0)

if [ -f ${DIRNAME}/../../functions ]; then
  . ${DIRNAME}/../../functions
else
  echo "ERROR: can ont find ${DIRNAME}/../../functions"; exit 1
fi

# Created by /usr/local/bin/figlet
clear
echo '                                                                                      '
echo '              ___                                   ____ _                            '
echo '             |_ _|_ __   __ _ _ __ ___  ___ ___    / ___| |__   ___  ___  ___  ___    '
echo '              | ||  _ \ / _  |  __/ _ \/ __/ __|  | |   |  _ \ / _ \/ _ \/ __|/ _ \   '
echo '              | || | | | (_| | | |  __/\__ \__ \  | |___| | | |  __/  __/\__ \  __/   '
echo '             |___|_| |_|\__, |_|  \___||___/___/   \____|_| |_|\___|\___||___/\___|   '
echo '                        |___/                                                         '
echo '                                   ____                                               '
echo '                                  |  _ \  ___ _ __ ___   ___                          '
echo '                                  | | | |/ _ \  _   _ \ / _ \                         '
echo '                                  | |_| |  __/ | | | | | (_) |                        '
echo '                                  |____/ \___|_| |_| |_|\___/                         '
echo '                                                                                      '
echo '          ----------------------------------------------------------------------------'
echo '                   Demonstration for Ingress Routing based on two different URL       '
echo '                                    by Sacha Dubois, Pivotal Inc                      '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

showK8sEnvironment

# --- LOAD CLOUD ENVIRONMENT ---
dom=$(pks cluster cl1 | grep "Kubernetes Master Host" | awk '{ print $NF }' | sed 's/cl1\.//g')

if [ -d ../../certificates/$dom -a "$dom" != "" ]; then 
  TLS_CERTIFICATE=../../certificates/$dom/fullchain.pem 
  TLS_PRIVATE_KEY=../../certificates/$dom/privkey.pem 
fi

#pks get-credentials cl1 > /dev/null 2>&1
#uid=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"cl1\")].context.user}")
#tok=$(kubectl describe secret $(kubectl get secret | grep $uid | awk '{print $1}') | grep "token:" | awk '{ print $2 }')

# --- CHECK IF CERTIFICATE HAS BEEN DEFINED ---
if [ "${TLS_CERTIFICATE}" == "" -o "${TLS_PRIVATE_KEY}" == "" ]; then 
  echo ""
  echo "ERROR: Certificate and Private-Key has not been specified. Please set"
  echo "       the following environment variables:"
  echo "       => export TLS_CERTIFICATE=<cert.pem>"
  echo "       => export TLS_PRIVATE_KEY=<private_key.pem>"
  echo ""
  exit 1 
else
  verifyTLScertificate $TLS_CERTIFICATE $TLS_PRIVATE_KEY
fi

kubectl get namespace cheese > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "ERROR: Namespace 'cheese' already exist"
  echo "       => kubectl delete namespace cheese"
  exit 1
fi

# --- CONVERT CERTS TO BASE64 ---
cert=$(base64 $TLS_CERTIFICATE) 
pkey=$(base64 $TLS_PRIVATE_KEY) 

# --- GENERATE INGRES FILES ---
cat ${DIRNAME}/template_cheese-ingress_tls.yml | sed -e "s/DOMAIN/$PKS_APPATH/g" > /tmp/cheese-ingress_tls.yml
echo " tls.crt: \"$cert\"" >> /tmp/cheese-ingress_tls.yml
echo " tls.key: \"$pkey\"" >> /tmp/cheese-ingress_tls.yml

prtHead "Create seperate namespace to host the Ingress Cheese Demo"
execCmd "kubectl create namespace cheese"

prtHead "Create the deployment for stilton-cheese"
execCmd "kubectl create deployment stilton-cheese --image=errm/cheese:stilton -n cheese"

prtHead "Create the deployment for stilton-cheese"
execCmd "kubectl create deployment cheddar-cheese --image=errm/cheese:cheddar -n cheese"

prtHead "Verify Deployment for stilton and cheddar cheese"
execCmd "kubectl get deployment,pods -n cheese"

prtHead "Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment stilton-cheese --type=NodePort --port=80 -n cheese"

prtHead "Create service type NodePort on port 80 for both deployments"
execCmd "kubectl expose deployment cheddar-cheese --type=NodePort --port=80 -n cheese"

prtHead "Verify services of cheddar-cheese and stilton-cheese"
execCmd "kubectl get svc -n cheese"

prtHead "Describe services cheddar-cheese and stilton-cheese"
execCmd "kubectl describe svc cheddar-cheese -n cheese"
execCmd "kubectl describe svc stilton-cheese -n cheese"

prtHead "Review ingress configuration file (/tmp/cheese-ingress_tls.yml)"
execCmd "more /tmp/cheese-ingress_tls.yml"

prtHead "Create ingress routing cheddar-cheese and stilton-cheese service"
execCmd "kubectl create -f /tmp/cheese-ingress_tls.yml -n cheese"
execCmd "kubectl get ingress -n cheese"
execCmd "kubectl describe ingress -n cheese"

prtHead "Open WebBrowser and verify the deployment"
echo "     => https://cheddar-cheese.$PKS_APPATH"
echo "     => https://stilton-cheese.$PKS_APPATH"
echo ""

exit 0
