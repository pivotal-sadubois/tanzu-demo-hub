#!/bin/bash

# V1.2 / schmidtst@vmware.com / 22. Dec 2021

# VMware Cloud Services / Tanzu Mission Control API Example

# https://developer.vmware.com/apis/csp/csp-iam/latest/authentication/
# https://developer.vmware.com/apis/1079/tanzu-mission-control#/

echo ""
echo "***********************************************************************"
echo "**                                                                   **"
echo "**  VMware Cloud Services (CSP) / Tanzu Mission Control API Example  **"
echo "**                                                                   **"
echo "**  V1.2 / schmidtst@vmware.com / 22. Dec 2021                       **"
echo "**                                                                   **"
echo "***********************************************************************"
echo ""

export TMC_HOST="tanzuemea.tmc.cloud.vmware.com"

## How to generate the API token for the Cloud Services Platform aka VMware Cloud Services

#    Login to the services at https://console.cloud.vmware.com
#    Click on your name at the top right and select My Account
#    Select the API Tokens tab this should bring you to 
#      https://console.cloud.vmware.com/csp/gateway/portal/#/user/tokens
#    Generate a new token (I used the sschmidt-test-token) and note the token value
#    Set the API_TOKEN to this value

# NOTE: set API_TOKEN in .secrets to avoid exposing it to Git
if [ ! -f ./.secrets ]
then
  echo "ERROR: ./.secrets file needed for settging API_TOKEN"
  if [ -f ./example.secrets ]
  then
    cat ./example.secrets
  fi
  exit 1
fi

. ./.secrets
if [ "${API_TOKEN}" == "" ]
then
  echo "ERROR: API_TOKEN not set, please add it to ./.secrets"
  exit 1
fi

#    Click on your name at the top right again
#    You will see the organization name and ID
#    Copy the organization id and set the CHECK_ORGANIZATION_ID value

export CHECK_ORGANIZATION_ID="fea0ee4b-bbf6-4444-b1d6-e493597d46a4" # tanzu-emea

echo ""
echo "    Please review the following settings"
echo ""
echo "    TMC_HOST=${TMC_HOST}"
echo "    CHECK_ORGANIZATION_ID=${CHECK_ORGANIZATION_ID}"
echo "    API_TOKEN=(not displayed for security reasons)"
echo ""
echo "    Edit ${0} if the values are not correct"
echo ""

# Print Debug Messages only if DEBUG="true"
#   Call: debugMsg "Key" "Value"
#   Output format: "Debug - Key: Value"
debugMsg() {
  if [ "${DEBUG}" == "true" ]
  then
    echo "Debug - ${1}: ${2}"
  fi
}

# Log Debug Messages only if DEBUG="true"
#   Call: debugLog "namePrefix" "nameSuffix"
#   Output file: /tmp/namePrefix_PID.nameSuffix"
debugLog() {
  if [ "${DEBUG}" == "true" ]
  then
    tee -a /tmp/${1}_${$}.${2}
  else
    cat
  fi
}

export VSET=$(tput smul)
export RESET=$(tput rmul)
printTitle() {
  echo -e "\n${VSET} *** ${1} *** ${RESET}\n"
}

###
### Cloud Services Platform API Calls
###

# get access token from api token
printTitle "CSP: Get access token from api token"
access_token=$(curl -s -X POST "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" \
   -H "accept: application/json" \
   -H "Content-Type: application/x-www-form-urlencoded" \
   -d "refresh_token=$API_TOKEN" | debugLog "access_token" "json" | jq -r '.access_token')

if [ "${access_token}" != "" ]
then
  echo "    Aquired Access Token"
else
  echo "    ERROR: Could not Aquire Access Token"
  exit 1
fi

debugMsg "Access Token" "${access_token}"

# get organization id
printTitle "CSP: Get organization id"
org_id=$(curl -s -X POST "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/details" \
   -H "Content-Type: application/json" \
   -d "{\"tokenValue\": \"$API_TOKEN\"}" | debugLog "org_id" "json" | jq -r '.orgId')

if [ "${org_id}" != "" ]
then
  echo "    Retrieved Organization ID ${org_id}"
else
  echo "    ERROR: Could not Retrieve Organization ID"
  exit 1
fi


debugMsg "Organization ID" "${org_id}"

# validate retrieved organization id
printTitle "CSP: Validate returned organization id"
if [ "${CHECK_ORGANIZATION_ID}" != "${org_id}" ]
then
  echo "Provided CHECK_ORGANIZATION_ID=${CHECK_ORGANIZATION_ID} does not match"
  echo "does not match returned org_id=${org_id}"
  exit 1
else
  echo "    Organization ID matches"
fi

###
### TMC API Calls
###

# OrganizationIAMPolicy
printTitle "TMC: Get organization level iam settings"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/organization:iam?fullName.orgId=${org_id}" \
  -H "Authorization: Bearer ${access_token}" \
  | debugLog "org_iam_policy" "json" \
  | jq -c '.policyList[].roleBindings[] | { Role: .role, Names: [ .subjects[].name ] }'

# ClusterGroupIAMPolicy
export TMC_CLUSTER_GROUP="sschmidt-cluster-group"
printTitle "TMC: Get cluster group level iam settings"
echo -e "    TMC_CLUSTER_GROUP=${TMC_CLUSTER_GROUP}\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clustergroups:iam/${TMC_CLUSTER_GROUP}?fullName.orgId=${orgId}" \
  -H "Authorization: Bearer ${access_token}" \
  | debugLog "clustergroup_iam_policy" "json" \
  | jq -c '.policyList[].roleBindings[] | { Role: .role, Names: [ .subjects[].name ] }'

# list role bindings for CLUSTER_ADMIN_NAME name
export CLUSTER_ADMIN_NAME="cladmin@epfl.ch"
printTitle "TMC: List role bindings for matching name"
echo -e "    TMC_CLUSTER_GROUP=${TMC_CLUSTER_GROUP}"
echo -e "    CLUSTER_ADMIN_NAME=${CLUSTER_ADMIN_NAME} matching .policyList[].roleBindings[].name\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clustergroups:iam/${TMC_CLUSTER_GROUP}?fullName.orgId=${orgId}" \
  -H "Authorization: Bearer ${access_token}" \
  | jq -c ".policyList[].roleBindings[] | select(.subjects[].name==\"${CLUSTER_ADMIN_NAME}\")"

# ClusterIAMPolicy
export CLUSTER_NAME="epfl-pks-cl1"
printTitle "List cluster level iam settings for specified cluster"
echo -e "    TMC_CLUSTER_GROUP=${TMC_CLUSTER_GROUP}"
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  | debugLog "cluster_iam_policy" "json" \
  | jq -c '.policyList[].roleBindings[] | { Role: .role, Names: [ .subjects[].name ] }'

# Update cluster iam policy. This effectively adds a user/role to the specified cluster
export DEV_USER_NAME="steve@sschmidt.ch"
export DEV_USER_ROLE="cluster.view"
printTitle "TMC: Update cluster specific iam policy"
echo -e "    DEV_USER_NAME=${DEV_USER_NAME}"
echo -e "    DEV_USER_ROLE=${DEV_USER_ROLE}"
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
echo -e "    Output .policy.roleBindings[] returned from the PUT API call\n"
curl -s -X PUT "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  -d "{\"roleBindings\":[{\"role\":\"${DEV_USER_ROLE}\",\"subjects\":[{\"name\":\"${DEV_USER_NAME}\",\"kind\":\"USER\"}]}]}" \
  | debugLog "update_cluster_iam_policy" "json" \
  | jq '.policy.roleBindings[]'

printTitle "TMC: List updated cluster specific iam policy"
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  | debugLog "list_updated_cluster_iam_policy" "json" \
  | jq -c '.policyList[].roleBindings[] | { Role: .role, Names: [ .subjects[].name ] }'

printTitle "TMC: List updated cluster specific iam policy matching sepcific role"
echo -e "    DEV_USER_ROLE=${DEV_USER_ROLE} matching .policyList[].roleBindings[].role"
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  | jq ".policyList[].roleBindings[] | select(.role==\"cluster.view\")"

printTitle "TMC: Delete cluster specific iam policy"
# Update (overwrite) policy for a Cluster - deleted if body is empty.
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
curl -s -X PUT "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  -d "" \
  | debugLog "delete_cluster_iam_policy" "json" \
  | jq -c .

printTitle "TMC: List updated cluster specific iam policy"
echo -e "    CLUSTER_NAME=${CLUSTER_NAME}\n"
curl -s -X GET "https://${TMC_HOST}/v1alpha1/clusters:iam/${CLUSTER_NAME}?fullName.name=${CLUSTER_NAME}&fullName.managementClusterName=attached&fullName.provisionerName=attached" \
  -H "Authorization: Bearer ${access_token}" \
  | debugLog "after_delete_cluster_iam_policy" "json" \
  | jq -c '.policyList[].roleBindings[] | { Role: .role, Names: [ .subjects[].name ] }'

echo ""
echo "***********************************************************************"
echo "**                                                                   **"
echo "**                  End of the CSP / TMC API Demo                    **"
echo "**                                                                   **"
echo "***********************************************************************"

exit 0

# list all clusters
# ClusterResourceService
# curl -s -X GET 'https://tanzuemea.tmc.cloud.vmware.com/v1alpha1/clusters?searchScope.name=*' -H "Authorization: Bearer ${access_token}" | jq .

# BinariesService
# curl -s -X GET 'https://tanzuemea.tmc.cloud.vmware.com/v1alpha1/system/binaries' -H "Authorization: Bearer ${access_token}" | jq .
