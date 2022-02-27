#!/bin/bash

echo "Setup of the Kubernetes Dashboard" 

export DOCKER_USER=sschmidtpvtl
export DOCKER_PASS=password
export DOCKER_MAIL=sschmidt@my.mail.com

echo "Check / adjust the following settings:"
echo "DOCKER_USER=$DOCKER_USER"
echo "DOCKER_PASS=$DOCKER_PASS"
echo "DOCKER_MAIL=$DOCKER_MAIL"

echo "Continue? (Y/n) "
read ans
if [[ ! ( "$ans" == "Y" || "$ans" == "y" || "$ans" == "" ) ]]
then
  echo "Stopped."; exit 0
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml

docker login docker.io -u $DOCKER_USER -p $DOCKER_PASS
kubectl create secret docker-registry regcred --docker-server=docker.io --docker-username=$DOCKER_USER --docker-password=$DOCKER_PASS --docker-email=$DOCKER_MAIL -n kubernetes-dashboard
kubectl patch serviceaccount kubernetes-dashboard -p '{"imagePullSecrets": [{"name": "regcred"}]}'   -n kubernetes-dashboard

cat > dashboard-admin-user.yaml <<xxEOFxx
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
xxEOFxx
kubectl apply -f dashboard-admin-user.yaml

cat > dashboard-admin-user-rbac.yaml <<xxEOFxx
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
xxEOFxx

kubectl apply -f dashboard-admin-user-rbac.yaml

cat > dashboard-service.yaml <<xxEOFxx
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
  type: LoadBalancer
  selector:
    k8s-app: kubernetes-dashboard
xxEOFxx

kubectl apply -f dashboard-service.yaml
sleep 10

kubectl get service/kubernetes-dashboard -n kubernetes-dashboard
LOADBALANCER_IP=$(kubectl get service/kubernetes-dashboard -n kubernetes-dashboard -o jsonpath="{.status.loadBalancer.ingress[].ip}")

TOKEN=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")

echo "Dashboard: https://$LOADBALANCER_IP/"
echo "Token:"
echo "$TOKEN"
