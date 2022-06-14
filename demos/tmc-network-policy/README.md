# TMC Network Policy

V1.0 / 10. Jun 2022 / schmidtst@vmware.com

Prerequisites:
- Tanzu Demo Hub Cluster
- tbs-kubeapps-fortune Demo done
- Fortune app with redis running

Preparation:
Deploy the redis container, which happens to include a redis-cli.

```
kubectl apply -f redis-pod.yaml
```

This is ther redis-pod.yaml

```YAML
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: redis
  name: redis-pod
spec:
  containers:
  - name: redis
    command:
    - /bin/bash
    args:
    - -c
    - "while true; do sleep 360; done"
    image: docker.io/bitnami/redis:6.2.7-debian-10-r0
    securityContext:
      runAsUser: 1001
```

## Setting The Scene

You have an application running with a frontend and a backend.
The frontend is accesible through the ingress for your customers.
Data is stored in the backend from the frontend.

```
open https://fortune.apps-contour.tkgs.sschmidt.ch/index.html
```
Display some fortunes, enter some new ones.

This is what the deployment on the cluster looks like.

```
kubectl get all -n tbs-kubeapps-fortune
```

What if you want to improve your security posture?

## What Could Go Wrong?

We have another redis container running in the default namespace.

```
kubectl get pods -n default
```

What can we do if we happen to get into this container?
Let us find out:

```
kubectl exec -it redis-pod -- bash
```
A bit of background. Services in Kubernetes are reachable at 
`service.namespace.svc.cluster.local`. If we happen to know a bit
about the cluster, we can come up with an educated guess.

```
redis-cli -h fortune-redis-master.tbs-kubeapps-fortune.svc.cluster.local keys '*'
```

```
1) "fortune:-4701345578729768294"
2) "fortune:4093849167603196482"
3) "fortune"
4) "fortune:-8646909762974846466"
5) "fortune:1512947162593126497"
```

```
redis-cli -h fortune-redis-master.tbs-kubeapps-fortune.svc.cluster.local type fortune:1512947162593126497
```

```
hash
```

```
redis-cli -h fortune-redis-master.tbs-kubeapps-fortune.svc.cluster.local hgetall fortune:1512947162593126497
```

```
1) "text"
2) "What ever your goal is in life, embrace it visualize it, and for it will be yours."
3) "id"
4) "1512947162593126497"
5) "_class"
6) "io.pivotal.pcf.demo.fortunebackend.Fortune"
```


## Introducing TMC Network Policy

TMC makes it easy to keep an overview of your network policies.
We start with organizing your Kubernetes namespaces into TMC
workspaces. Let's attach the `tbs-kubeapps-fortune` namespace to
an existing workspace named `sschmidt-fortune`.

No we go to Policies -> Assignements -> Network and select our
workspace. There we click the `Create Network Policy` button.
Select the `deny-all-to-pods` policy. You may name it as
`sschmidt-deny-all-to-pods` and as the pod selectors use the
key `app.kubernetes.io/name` and label `redis`, then click
`Add Label` and finaly `Create Policy`.

This is how quick and easy it is to define a network policy and
keeping track of it. 

Do you think we can still use the redis-cli to peek at the data
of our fortune app?

Also go back and see if the application is still working.

## More Ways

What happens if you change the pod selector to key `app` and 
label to `fortune-app`?

## Hidden Gems

If you look at the TMC workspace hierarchy, you can set policies
at the organization level. These will be automatically inherited
by all workspaces. This enables you to protect all critical
backend pods from undesired connections.
