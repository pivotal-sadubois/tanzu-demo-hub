#!/bin/bash
# ============================================================================================
# File: ........: deploy_tkgmc_azure.sh
# Language .....: bash
# Author .......: Sacha Dubois, Pivotal
# --------------------------------------------------------------------------------------------
# Description ..: Deploy the TKG Management Cluster on Azure
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
echo '                     _____ _  ______   ____                                           '
echo '                    |_   _| |/ / ___| |  _ \  ___ _ __ ___   ___                      '
echo '                      | | |   / |  _  | | | |/ _ \  _   _ \ / _ \                     '
echo '                      | | |   \ |_| | | |_| |  __/ | | | | | (_) |                    '
echo '                      |_| |_|\_\____| |____/ \___|_| |_| |_|\___/                     '
echo '                                                                                      '                                              
echo '          ----------------------------------------------------------------------------'
echo '                      Deploy TKG Management Cluster on Microsoft Azure                '
echo '                                  by Sacha Dubois, VMware Inc                         '
echo '          ----------------------------------------------------------------------------'
echo '                                                                                      '

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

export TDH_DEPLOYMENT_ENV_NAME="Azure"
export TKG_CONFIG=/Users/sdubois/workspace/tanzu-demo-hub/config/tkgmc-azure-westeurope.yaml

checkCloudCLI
checkCloudAccess
checkKeyPairs

messageTitle ""
messageTitle "TKG Documentation"
messageTitle " - TKG 1.2 Documentation"
messageTitle "   https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.2/vmware-tanzu-kubernetes-grid-12/GUID-index.html"
messageTitle " - TKG 1.2 Deploying and Managing Management Clusters"
messageTitle "   https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.2/vmware-tanzu-kubernetes-grid-12/GUID-mgmt-clusters-deploy-management-clusters.html"
messageTitle " - TKG 1.2 Create Tanzu Kubernetes Clusters"
messageTitle "   https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.0/vmware-tanzu-kubernetes-grid-10/GUID-tanzu-k8s-clusters-create.html"
messageTitle " - TKG 1.2 Software Download"
messageTitle "   https://my.vmware.com/web/vmware/downloads/details?downloadGroup=TKG-100&productId=988&rPId=45068"
messageTitle ""

#prtHead "Accept the Base OS Image License"
#execCmd "az vm image accept-terms --publisher vmware-inc --offer tkg-capi --plan k8s-1dot19dot1-ubuntu-1804"

# GENERATE INGRES FILES
if [ ! -f ~/.tanzu-demo-hub/KeyPair-Azure.pem ]; then 
  prtHead "Generate SSH-KEY for Access"
  rm -f ~/.tanzu-demo-hub/KeyPair-Azure.pem ~/.tanzu-demo-hub/KeyPair-Azure.pub 
  execCmd "ssh-keygen -t rsa -b 4096 -f ~/.tanzu-demo-hub/KeyPair-Azure -P \"\""
  #ssh-keygen -t rsa -b 4096 -f ~/.tanzu-demo-hub/KeyPair-Azure -P "" > /dev/null 2>&1
  mv ~/.tanzu-demo-hub/KeyPair-Azure ~/.tanzu-demo-hub/KeyPair-Azure.pem

  cat ~/.tanzu-demo-hub/KeyPair-Azure.pub
  echo ""
else
  prtHead "Display SSH Public Key for Azure VM Access"
  execCmd "export AZURE_LOCATION=\"$(cat ~/.tanzu-demo-hub/KeyPair-Azure.pub)\""
fi

prtHead "TKG Management Cluster Installation on Azure:"
execCmd "tkg init --ui -b 127.0.0.1:8082"
exit

prtHead "Apply the prometheus RBAC policy spec"
execCmd "kubectl apply -f prometheus-rbac.yaml -n monitoring"

prtHead "Apply the prometheus config-map spec"
execCmd "kubectl apply -f prometheus-config-map.yaml -n monitoring"

prtHead "Deploy the Prometheus application spec and verify all pods transitioning to Running"
execCmd "kubectl apply -f prometheus-deployment.yaml -n monitoring"
execCmd "kubectl wait --for=condition=ready pod -l app=prometheus-server --timeout=60s -n monitoring"
execCmd "kubectl get pods -n monitoring"

prtHead "Install the grafana Helm chart"
execCmd "helm install --name grafana ./grafana --namespace monitoring > /dev/null 2>&1"

prtHead "Review ingress configuration file (/tmp/grafana_ingress.yml)"
execCmd "more /tmp/grafana_ingress.yml"

prtHead "Create ingress routing for the grafana service"
execCmd "kubectl create -f /tmp/grafana_ingress.yml -n monitoring"
execCmd "kubectl get ingress -n monitoring"
execCmd "kubectl describe ingress -n monitoring"

prtHead "Collect and record the secret"
execCmd "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | /usr/bin/base64 --decode; echo"

prtHead "Open WebBrowser and verify the deployment"
prtText "  => http://grafana.apps-${PKS_CLNAME}.${PKS_ENNAME}"; read x

prtHead "Configure the prometheus plug-in"
prtText "  => Select > Add data source"
prtText "  => Select > Prometheus"
prtText "  => URL: http://prometheus.monitoring.svc.cluster.local:9090"
prtText "  => Select > Save and Test"; read x

prtHead "Import the Kubernetes Dashboard"
prtText "  => Select > '+' in left pane then 'Import'"
prtText "  => Enter ID: 1621"
prtText "  => Select: Prometheus"; read x


