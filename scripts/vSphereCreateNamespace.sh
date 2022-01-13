#!/bin/bash
# ############################################################################################
# File: ........: vSphereCreateNamespace.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware Tanzu
# Description ..: vSphere create a vSphere Namespace
# ############################################################################################

usage() {
  echo ""
  echo "USAGE: $0 [options] -s <http://vsphere_server> -u <vsphere_user> -p <vsphere_password>"
  echo "            Options:  -d <vsphere_server>    # vSphere Server (inkl. http Url)"
  echo "                      -c <vsphere_user>      # vSphere User"
  echo "                      -c <vsphere_password>  # vSphere Password"
  echo "                      -n <vsphere_namespace> # vSphere Namespace"
  echo ""
  echo "example: $0 -s https://vcsa-01.haas-464.pez.vmware.com -u administrator@vsphere.local -p xxxxxxxxxxxx -n namespace_test" 
  echo ""
}

# ------------------------------------------------------------------------------------------
# Function Name ......: vSphereAPI_getToken
# Function Purpose ...: Create a vSphere Namespace
# ------------------------------------------------------------------------------------------
# Argument ($1) ......: vSphere API Token
#          ($2) ......: vSphere Server Name
#          ($3) ......: vSphere Namespace name
# ------------------------------------------------------------------------------------------
# Return Value .......: 0 on Success, 1 on failure
# ------------------------------------------------------------------------------------------
vSphereAPI_getToken() {
  VCENTER_SERVER="$1"
  VCENTER_USER="$2"
  VCENTER_PASS="$3"
  USERPASS="${VCENTER_USER}:${VCENTER_PASS}"

  curl -k -X POST "${VCENTER_SERVER}/rest/com/vmware/cis/session" -u "$USERPASS" 2>/dev/null | jq -r '.value'
}

# ------------------------------------------------------------------------------------------
# Function Name ......: vSphereAPI_createNamespace
# Function Purpose ...: Create a vSphere Namespace
# ------------------------------------------------------------------------------------------
# Argument ($1) ......: vSphere API Token
#          ($2) ......: vSphere Server Name
#          ($3) ......: vSphere Namespace name
# ------------------------------------------------------------------------------------------
# Return Value .......: 0 on Success, 1 on failure
# ------------------------------------------------------------------------------------------
vSphereAPI_createNamespace() {
  API_TOKEN=$1
  VCENTER_SERVER=$2
  NAMESPACE=$3

  # --- CREATE VSPHERE NAMESPACE ---
  stt=$(curl -k -X GET -H "vmware-api-session-id: $API_TOKEN" ${VCENTER_SERVER}/api/vcenter/namespaces/instances/$NAMESPACE 2>/dev/null | jq -r '.cluster')
  if [ "$stt" == "" -o "$stt" == "null" ]; then
    vs_cluster=$(curl -k -X GET -H "vmware-api-session-id: $API_TOKEN" ${VCENTER_SERVER}/api/vcenter/namespace-management/clusters 2>/dev/null | jq -r '.[].cluster')
    VSPHERE_CONFIG=/tmp/vsphere_config.json; rm -f $OKTA_CONFIG
    echo '{'                                                                         >  $VSPHERE_CONFIG
    echo "  \"cluster\": \"$vs_cluster\","                                           >> $VSPHERE_CONFIG
    echo "  \"namespace\": \"$NAMESPACE\""                                           >> $VSPHERE_CONFIG
    echo '}'                                                                         >> $VSPHERE_CONFIG

    curl -k -X POST -H "vmware-api-session-id: $API_TOKEN" ${VCENTER_SERVER}/api/vcenter/namespaces/instances \
         -H 'Content-type: application/json' -d "@$VSPHERE_CONFIG" > /tmp/error.log 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to set vSphere Namespace $NAMESPACE"
      echo "       => curl -k -X POST -H \"vmware-api-session-id: $API_TOKEN\" ${VCENTER_SERVER}/api/vcenter/namespaces/instances \\"
      echo "               -H 'Content-type: application/json' -d \"@$VSPHERE_CONFIG\""

      exit 1
    fi

    echo "vSphere Namespace $VSPHERE_NAMESPACE has been created"
  fi

  # --- GET STORAGE POLICY ID FOR 'TANZU' ---
  vm_policy=$(curl -k -X GET -H 'Content-type: application/json' \
                   -H "vmware-api-session-id: $API_TOKEN" ${VCENTER_URL}/rest/vcenter/storage/policies 2>/dev/null | \
                   jq -r '.value[] | select(.name == "tanzu" ).policy')


  # --- UPDATE VSPHERE NAMESPACE CONFIG ---
  VSPHERE_CONFIG=/tmp/vsphere_config.json; rm -f $OKTA_CONFIG
  echo '{'                                                                         >  $VSPHERE_CONFIG
  echo '  "description": "Tanzu Demo Hub - Demo Namespace 3",'                     >> $VSPHERE_CONFIG
  echo '  "vm_service_spec": {'                                                    >> $VSPHERE_CONFIG
  echo '    "vm_classes": ['                                                       >> $VSPHERE_CONFIG
  echo '      "best-effort-medium",'                                               >> $VSPHERE_CONFIG
  echo '      "best-effort-large",'                                                >> $VSPHERE_CONFIG
  echo '      "best-effort-xlarge",'                                               >> $VSPHERE_CONFIG
  echo '      "guaranteed-medium",'                                                >> $VSPHERE_CONFIG
  echo '      "guaranteed-large",'                                                 >> $VSPHERE_CONFIG
  echo '      "guaranteed-xlarge"'                                                 >> $VSPHERE_CONFIG
  echo '    ]'                                                                     >> $VSPHERE_CONFIG
  echo '  },'                                                                      >> $VSPHERE_CONFIG
  echo '  "storage_specs": ['                                                      >> $VSPHERE_CONFIG
  echo '    {'                                                                     >> $VSPHERE_CONFIG
  echo "      \"policy\": \"$vm_policy\""                                          >> $VSPHERE_CONFIG
  echo '    }'                                                                     >> $VSPHERE_CONFIG
  echo '  ]'                                                                       >> $VSPHERE_CONFIG
  echo '}'                                                                         >> $VSPHERE_CONFIG

  curl -k -X PATCH -H 'Content-type: application/json' \
                   -H "vmware-api-session-id: $API_TOKEN" ${VCENTER_SERVER}/api/vcenter/namespaces/instances/$NAMESPACE \
                   -d "@$VSPHERE_CONFIG" > /tmp/error.log 2>&1; ret=$?
  if [ $ret -ne 0 ]; then
    logMessages /tmp/error.log
    logMessages $VSPHERE_CONFIG
    echo "ERROR: failed to Patch vSphere Namespace $NAMESPACE"
    echo "       => curl -k -X PATH -H \"vmware-api-session-id: $API_TOKEN\" ${VCENTER_SERVER}/api/vcenter/namespaces/instances/$NAMESPACE \\"
    echo "               -H 'Content-type: application/json' -d \"@$VSPHERE_CONFIG\""

    exit 1
  else
    echo "vSphere Namespace $VSPHERE_NAMESPACE has been updated"
  fi
}

while [ "$1" != "" ]; do
  case $1 in
    -s)  VCENTER_URL=$2;;
    -u)  VCENTER_USER=$2;;
    -p)  VCENTER_PASS=$2;;
    -n)  VSPHERE_NAMESPACE=$2;;
  esac
  shift
done

if [ "$VCENTER_URL" == "" -o "$VCENTER_URL" == "" -o "$VCENTER_URL" == "" -o "$VSPHERE_NAMESPACE" == "" ]; then 
  usage
  exit 1
fi

TDH_VSPHERE_API_TOKEN=$(vSphereAPI_getToken "$VCENTER_URL" "$VCENTER_USER" "$VCENTER_PASS")

vSphereAPI_createNamespace $TDH_VSPHERE_API_TOKEN $VCENTER_URL $VSPHERE_NAMESPACE

exit 0

