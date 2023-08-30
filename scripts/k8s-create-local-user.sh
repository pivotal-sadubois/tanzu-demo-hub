#!/bin/bash

if [ "$1" == "" ]; then 
  echo "USAGE: $0 <user>"; exit 1
fi

USER=$1

rm -f /tmp/$${USER}.csr /tmp/${USER}.pem /tmp/${USER}.csr-csr.yaml /tmp/${USER}.csr-user.crt
kubectl delete certificatesigningrequests user-request-${USER} > /dev/null 2>&1
kubectl delete certificate user-request-${USER} > /dev/null 2>&1
kubectl delete rolebinding developer-binding-${USER} > /dev/null 2>&1
kubectl delete role developer > /dev/null 2>&1

openssl genrsa -out /tmp/${USER}.pem > /dev/null 2>&1
openssl req -new -key /tmp/${USER}.pem -out /tmp/${USER}.csr -subj "/CN=${USER}" > /dev/null 2>&1

cat << EOF > /tmp/${USER}-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user-request-${USER}
spec:
  groups:
  - system:authenticated
  request: $(cat /tmp/${USER}.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF

cat << EOF > /tmp/role_developer.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - services
  verbs:
  - create
  - get
  - list
  - delete
EOF

cat << EOF > /tmp/developer-binding-${USER}.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding-${USER}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${USER}
EOF

kubectl create -f /tmp/${USER}-csr.yaml
sleep 10
kubectl certificate approve user-request-${USER}
kubectl get csr

kubectl get csr user-request-${USER} -o jsonpath='{.status.certificate}'| \
base64 -d > /tmp/${USER}-user.crt

echo "/tmp/role_developer.yaml"
echo "/tmp/developer-binding-${USER}.yaml"
kubectl apply -f /tmp/role_developer.yaml
kubectl apply -f /tmp/developer-binding-${USER}.yaml

echo "kubectl --client-key=/tmp/${USER}.pem --client-certificate=/tmp/${USER}-user.crt get ns"
