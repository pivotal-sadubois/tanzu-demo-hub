# Kubernetes UI Access

Using the Kubernetes dashboard

## Deploy the Dashboard

The dashboard is not deployed by default. Check the official documentation for updates of the command below.

[Kubernetes Dashboard Docu Link](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
```

Check the deplyoment with

```
kubectl get all -n kubernetes-dashboard
```

If you run into Docker rate limit issues, see for [Docker Rate Limit Workaround](#Docker-Rate-Limit-Issues) for a possible solution.

## Accessing the Dashboard

Once deployed, expose the kubernetes dashboard service to your local machine. Using the kubectl proxy feature.
> NOTE: this only works on your local machine. You can create a service account and create a cluster role binding to expose the dashboard through an ingress.

```
kubectl proxy
```

Now you are ready to access the dashboard and inspect your cluster.

```
open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Deploy your first application

To deploy your first application, click the "+" sign in the upper right corner. Choose between input, file upload and form input mode. The form input mode has an advanced option where you can configure all relevant parameters.

```
App name:            echoserver
Container Image:     k8s.gcr.io/echoserver:1.4
Number of pods:      1
Service:             None
DEPLOY
```

## Scale up

After your first deplyoment, you can now edit that deployment to scale it up, update to new versions, inspect the logs of your pods and much more. Have fun!

First, scale your deployment from 1 to 3. Watch the results.

## Update Application Version

Then change the container image from `k8s.gcr.io/echoserver:1.4` to `k8s.gcr.io/echoserver:1.2`. Notice the rolling update - bringin up one new and scaling down one old.

## Inspect Pod Logs, Exec to Container

Also display the logs for a pod and try to exec into the echoserver.

## Troubleshooting

And now for some real fun - what if things go wrong?

```
App name:            failserver
Container Image:     k8s.gcr.io/failserver:latest
Number of pods:      1
Service:             None
DEPLOY
```

Can you find the error messages?

## Docker Rate Limit Issues

If you run into docker pull rate limit, sign up for an account if you don't have one already [Create a Docker ID](https://hub.docker.com/signup).
Then do the following with your Docker ID (docker username):

```
export DOCKER_USER=sschmidtpvtl
export DOCKER_PASS=password
export DOCKER_MAIL=sschmidt@my.mail.com
docker login docker.io -u $DOCKER_USER -p $DOCKER_PASS
kubectl create secret docker-registry regcred --docker-server=docker.io --docker-username=$DOCKER_USER --docker-password=$DOCKER_PASS --docker-email=$DOCKER_MAIL -n kubernetes-dashboard
kubectl patch serviceaccount kubernetes-dashboard -p '{"imagePullSecrets": [{"name": "regcred"}]}'   -n kubernetes-dashboard
```

## Exposing the Dashboard

As per the documentation you can create a service account and grant a cluster role. The example will create a setup with full privileges. [Creating a sample user](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)

Create the file `dashboard-admin-user.yaml`

```YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```

```
kubectl apply -f dashboard-admin-user.yaml
```

Create the file `dashboard-admin-user-rbac.yaml`

```YAML
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
```

```
kubectl apply -f dashboard-admin-user-rbac.yaml
```

We are now setup to retrieve the token needed to login to the dashboard.

```
TOKEN=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
echo $TOKEN
```

The quick and dirty way is to change the service from type ClusterIP to LoadBalancer. As an alternative you can create an Ingress.

```
kubectl edit service/kubernetes-dashboard -n kubernetes-dashboard
```

```
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
```

Once the IP address is assigned, you can retrieve the LoadBalancer address and open the dashboard with the browser.

```
kubectl get service/kubernetes-dashboard -n kubernetes-dashboard
LOADBALANCER_IP=$(kubectl get service/kubernetes-dashboard -n kubernetes-dashboard -o jsonpath="{.status.loadBalancer.ingress[].ip}")
```

```
curl -k https://$LOADBALANCER_IP/
```
