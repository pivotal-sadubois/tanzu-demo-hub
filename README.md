# Tanzu Demo Hub

The Tanzu Demo Hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

![TanzuDemoHub](https://github.com/pivotal-sadubois/tanzu-demo-hub/blob/main/files/TanzuDemoHub.jpg)

*Platfomrm Services installed by Tanzu Demo Hub*
- CertManager (Let's Enscript Wildcard Certificates)
  - TKG on Azure (*.aztkg.<your-domain>.com)
  - TKG on AWS (*.awstkg.<your-domain>.com)
  - TKG on vSphere (*.vstkg.<your-domain>.com)
- LoadBalancer
  - MetalLB on Minikube
  - El2 LoadBalancer on AWS
  - Standard LoadBlancer on Microsoft Azure
- Contour Ingress Controller (Bitnami)
- Nginx Ingress Controller (Bitnami) 
- Harbor Registry (Bitnami)  
- Tanzu Build Service
- Tanzu Data Postgress Operator
- Spring Cloud Gateway

*Prebuild Demos*
- Kubernetes Pod Security
- TMC Policies
- TBS PetClinic Demo
- Tanzu Data Postgres

*Supported Environments*
- [Tanzu-Demo-Hub on Minikube (#tanzu-demo-hub-on-minikube)
- Tanzu-Demo-Hub on vSphere (#tanzu-demo-hub-on-vsphere)
- Tanzu-Demo-Hub on AWS (#tanzu-demo-hub-on-aws)
- Tanzu-Demo-Hub on Azure (#tanzu-demo-hub-on-azure)

*Requirements*
- AWS Route53 Domain (https://aws.amazon.com/route53)

# Tanzu-Demo-Hub on Minikube
```
$ ./deployMiniKube 

Tanzu Demo Hub - Deploy MiniKube cluster
by Sacha Dubois, VMware Inc,
-----------------------------------------------------------------------------------------------------------
DEPLOYMENT                       PLATFORM  PROFILE         MGMT-CLUSTER         PLAN  CONFIGURATION
----------------------------------------------------------------------------------------------------------------
minikube-tanzu-demo-hub.cfg      minikube  tanzu-demo-hub  n/a                  n/a   

USAGE: ./deployMiniKube [options] -d <deployment> [--clean|--debug]
Sachas-MacBook-Pro:tanzu-demo-hub sdu$ 

$ ./deployMiniKube -d minikube-tanzu-demo-hub.cfg

```

# Tanzu-Demo-Hub on Azure
```
$ ./deployTKGmc
CONFIURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
-----------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg              AWS     awstkg  tkgmc-aws-<TDH_USER>           dev   tkgmc-aws.yaml
tkgmc-aws-prod.cfg             AWS     awstkg  tkgmc-aws-dev-<TDH_USER>       prod  tkgmc-aws-dev.yaml
tkgmc-azure-dev.cfg            Azure   aztkg   tkgmc-azure-<TDH_USER>         dev   tkgmc-azure.yaml
tkgmc-azure-prod.cfg           Azure   aztkg   tkgmc-azure-<TDH_USER>         prod  tkgmc-azure.yaml
tkgmc-dev-vsphere-macbook.cfg  vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-dev.cfg          vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-tkgm-dev.cfg     vSphere vstkg   tkgmc-vsphere-<TDH_USER>       dev   tkgmc-vsphere-tkgm.yaml
-----------------------------------------------------------------------------------------------------------
USAGE: ./deployTKGmc [oprions] <deployment>
            --delete                 # Delete Management Cluster and Jump Server
            --debug                  # default (disabled)
            --native                 # Use 'native' installed tools instead of the tdh-tools container

./deployTKGmc tkgmc-vsphere-tkgm-dev.cfg
```

```
$ ./deployMiniKube -d minikube-tanzu-demo-hub.cfg

Tanzu Demo Hub - Deploy MiniKube cluster
by Sacha Dubois, VMware Inc,
-----------------------------------------------------------------------------------------------------------
MiniKube Verify Addons
 ▪ Minikube Addon: default-storageclass ......................: enabled
 ▪ Minikube Addon: metrics-server ............................: enabled
 ▪ Minikube Addon: metallb-system ............................: enabled
Verify MetalLB Loadbalancer
 ▪ Metallb LoadBalancer Status ...............................: active
 ▪ Metallb LoadBalancer IP-Pool ..............................: 192.168.64.100-192.168.64.120
Supporting services access (Pivotal Network, AWS Route53)
 ▪ Pivotal Network Token .....................................: 1edb78016b054bbaab960b3007a77b12-r
 ▪ Tanzu Demo Hube User ......................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .............................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ..........................: 
 ▪ AWS Route53 ZoneID ........................................: Z1X9T7571BMHB5
Cleaning Up kubectl config
MiniKube Status and Configuration
 ▪ MiniKube Profile ..........................................: tdh-minikube-sadubois
 ▪ MiniKube Version ..........................................: v1.18.1
 ▪ MiniKube Status ...........................................: Running
 ▪ Minikube Disk .............................................: 71680
 ▪ Minikube Memory ...........................................: 16384
 ▪ Minikube CPU's ............................................: 6
 ▪ Minikube Driver ...........................................: hyperkit
 ▪ Minikube Nodes
   ------------------------------------------------------------------------
   tdh-minikube-sadubois	192.168.64.41
   ------------------------------------------------------------------------
 ▪ MiniKube ServerIP .........................................: 192.168.64.41
TDH Tools Docker Container (tdh-tools)
 ▪ Dockerfile Checksum (files/tdh-tools/Dockerfile) ..........: 3776
 ▪ Docker Image (tdh-tools) Checksum .........................: 3776 => No Rebuild required
 ▪ Running TDH Tools Docker Container ........................: tdh-tools:latest /Users/sdu/workspace/tanzu-demo-hub/deployMiniKube -d minikube-tanzu-demo-hub.cfg
Verify Cert Manager
 ▪ Cert Manager Namespace: ...................................: cert-manager
 ▪ Cert Manager Helm Chart: ..................................: cert-manager-v1.1.0
 ▪ Cert Manager Version: .....................................: v1.1.0
 ▪ Cert Manager Status: ......................................: deployed
 ▪ Cert Manager Installed/Updated: ...........................: 2021-06-08 00:53:36.506931 +0200 CEST
Verify Ingress Contour
 ▪ Ingress Contour Namespace: ................................: ingress-contour
 ▪ Ingress Contour Helm Chart: ...............................: contour-4.2.2
 ▪ Ingress Contour Version: ..................................: 1.14.0
 ▪ Ingress Contour Status: ...................................: deployed
 ▪ Ingress Contour Installed/Updated: ........................: 2021-06-08 01:05:13.835878 +0200 CEST
Verify LetsEnscript ClusterIssuer
 ▪ LetsEnscript Issuer Name ..................................: letsencrypt-staging
 ▪ LetsEnscript DNSZone ......................................: *.apps-contour.local.pcfsdu.com
 ▪ LetsEnscript DNSZone ......................................: *.apps-nginx.local.pcfsdu.com
 ▪ LetsEnscript Request Requested ............................: 2021-06-07T23:06:39Z
 ▪ LetsEnscript Request Reason ...............................: ACMEAccountRegistered
 ▪ LetsEnscript Request Status ...............................: True
Verify LetsEnscript Certificate
 ▪ LetsEnscript Certificate Name .............................: tanzu-demo-hub
 ▪ LetsEnscript Certificate Secret ...........................: tanzu-demo-hub-tls
------------------------------------------------------------------------------------------------------------------------
        Subject: CN = *.apps-contour.local.pcfsdu.com
                DNS:*.apps-contour.local.pcfsdu.com, DNS:*.apps-nginx.local.pcfsdu.com
------------------------------------------------------------------------------------------------------------------------
Harbor Reistry
 ▪ Verify Harbor Reistry .....................................: bitnami/harbor
   Harbor Reistry Namespace: .................................: registry-harbor
   Harbor Reistry Helm Chart: ................................: harbor-9.2.2
   Harbor Reistry Version: ...................................: 2.1.2
   Harbor Reistry Status: ....................................: deployed
   Harbor Reistry Installed/Updated: .........................: 2021-06-08 01:09:25.175152 +0200 CEST
 ▪ TDH Certificate Issuer: ...................................: Let's Encrypt
 ▪ TDH Certificate File: .....................................: tdh-cert.pem
 ▪ TDH Certificate CN: .......................................: R3
 ▪ Let's Encrypt Intermediate Certificate: ...................: /Users/sdu/.tanzu-demo-hub/certificates/R3
 ▪ Let's Encrypt Intermediate Certificate Url: ...............: https://letsencrypt.org/certs/lets-encrypt-r3.pem
 ▪ Let's Encrypt Intermediate Certificate File: ..............: /Users/sdu/.tanzu-demo-hub/certificates/lets-encrypt-r3.pem
 ▪ Let's Encrypt Root Certificate: ...........................: /Users/sdu/.tanzu-demo-hub/certificates/R3
 ▪ Let's Encrypt Root Certificate Url: .......................: https://letsencrypt.org/certs/isrgrootx1.pem
 ▪ Let's Encrypt Root Certificate File: ......................: /Users/sdu/.tanzu-demo-hub/certificates/isrgrootx1.pem
Verify RootCA with the Certificate (tanzu-demo-hub-tls)
 ▪ Verify Cert (tdh-cert.pem) with RootCA (ca.pem) ...........: /Users/sdu/.tanzu-demo-hub/certificates/tdh-cert.pem: OK
 ▪ Verify Cert (tdh-cert.pem) with CertKey (tdh-key.pem) .....: ok
Tanzu Build Service
 ▪ Verify Tanzu Build Service ................................: 1.1.2
 ▪ Verify Dependency Descriptors .............................: successfuly installed
VMware Tanzu Postgres
 ▪ Verify Postgres Operator ..................................: postgres-operator-v1.1.0
   Helm Chart Name ...........................................: postgres-operator
   Helm Chart Version ........................................: v1.1.0
   Helm Chart Status .........................................: deployed
   Helm Chart Installed/Updated ..............................: 2021-06-08 06:54:15.036058 +0200 CEST
Minio S3 Object Storage
 ▪ Verify Minio S3 ...........................................: minio-6.7.2
   Helm Chart Name ...........................................: minio
   Helm Chart Version ........................................: 2021.4.6
   Helm Chart Status .........................................: deployed
   Helm Chart Installed/Updated ..............................: 2021-06-08 06:54:20.617576 +0200 CEST
   Minio Internal Name .......................................: tdh-minio.default.svc.cluster.local
   Minio Management Portal ...................................: https://minio.apps-contour.local.pcfsdu.com
   Minio Access Key ..........................................: mOS0kPhnOc
   Minio Secret Key ..........................................: wiKqYNqWO4EWtdN15fTxlY8ZzDVmHwjkXegCsce2
   -----------------------------------------------------------------------------------------------------------
   Test Minio S3 Access: (https://docs.min.io/docs/minio-client-complete-guide)
     => mc alias set minio https://minio.apps-contour.local.pcfsdu.com mOS0kPhnOc wiKqYNqWO4EWtdN15fTxlY8ZzDVmHwjkXegCsce2
     => mc ls minio
   -----------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------
Tanzu Kubernetes Grid Cluster (tdh-minikube-sadubois) build completed
-----------------------------------------------------------------------------------------------------------
1.) Set KUBECONFIG and set the cluster context
    => export KUBECONFIG=/tmp/tdh-minikube-sadubois.kubeconfig:~/.kube/config
    => minikube -p tdh-minikube-sadubois update-context
    => kubectl config use-context tdh-minikube-sadubois
    => kubectl config get-contexts
2.) Relaxing Pod Security in cluster (tdh-minikube-sadubois)
    # Allow Privileged Pods for the Cluster
    => kubectl create clusterrolebinding tanzu-demo-hub-privileged-cluster-role-binding \
        --clusterrole=vmware-system-tmc-psp-privileged --group=system:authenticated
    # Allow Privileged Pods for a Namespace (my-namespace)
    => kubectl create rolebinding tanzu-demo-hub-privileged-my-namespace-role-binding \
        --clusterrole=vmware-system-tmc-psp-privileged --group=system:authenticated -n my-namespace
```

# Tanzu-Demo-Hub on Azure
```
$ ./deployTKGmc
CONFIURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
-----------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg              AWS     awstkg  tkgmc-aws-<TDH_USER>           dev   tkgmc-aws.yaml
tkgmc-aws-prod.cfg             AWS     awstkg  tkgmc-aws-dev-<TDH_USER>       prod  tkgmc-aws-dev.yaml
tkgmc-azure-dev.cfg            Azure   aztkg   tkgmc-azure-<TDH_USER>         dev   tkgmc-azure.yaml
tkgmc-azure-prod.cfg           Azure   aztkg   tkgmc-azure-<TDH_USER>         prod  tkgmc-azure.yaml
tkgmc-dev-vsphere-macbook.cfg  vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-dev.cfg          vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-tkgm-dev.cfg     vSphere vstkg   tkgmc-vsphere-<TDH_USER>       dev   tkgmc-vsphere-tkgm.yaml
-----------------------------------------------------------------------------------------------------------
USAGE: ./deployTKGmc [oprions] <deployment>
            --delete                 # Delete Management Cluster and Jump Server
            --debug                  # default (disabled)  
            --native                 # Use 'native' installed tools instead of the tdh-tools container

./deployTKGmc tkgmc-vsphere-tkgm-dev.cfg

```
# Tanzu-Demo-Hub on AWS
```
$ ./deployTKGmc
CONFIURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
-----------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg              AWS     awstkg  tkgmc-aws-<TDH_USER>           dev   tkgmc-aws.yaml
tkgmc-aws-prod.cfg             AWS     awstkg  tkgmc-aws-dev-<TDH_USER>       prod  tkgmc-aws-dev.yaml
tkgmc-azure-dev.cfg            Azure   aztkg   tkgmc-azure-<TDH_USER>         dev   tkgmc-azure.yaml
tkgmc-azure-prod.cfg           Azure   aztkg   tkgmc-azure-<TDH_USER>         prod  tkgmc-azure.yaml
tkgmc-dev-vsphere-macbook.cfg  vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-dev.cfg          vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-tkgm-dev.cfg     vSphere vstkg   tkgmc-vsphere-<TDH_USER>       dev   tkgmc-vsphere-tkgm.yaml
-----------------------------------------------------------------------------------------------------------
USAGE: ./deployTKGmc [oprions] <deployment>
            --delete                 # Delete Management Cluster and Jump Server
            --debug                  # default (disabled)  
            --native                 # Use 'native' installed tools instead of the tdh-tools container

./deployTKGmc tkgmc-aws-dev.cfg

```
```
$ ./deployTKGmc tkgmc-azure-dev.cfg

Tanzu Demo Hub - Deploy TKG Management Cluster
by Sacha Dubois, VMware Inc,
----------------------------------------------------------------------------------------------------------------------------------------------
TDH Tools Docker Container (tdh-tools)
 ▪ Dockerfile Checksum (files/tdh-tools/Dockerfile) ......: 7796
 ▪ Docker Image (tdh-tools) Checksum .....................: 7796 => No Rebuild required
 ▪ Running TDH Tools Docker Container ....................: tdh-tools:latest /Users/sdu/workspace/tanzu-demo-hub/deployTKGmc tkgmc-azure-dev.cfg
Cleaning Up kubectl config
Supporting services access (Pivotal Network, AWS Route53)
 ▪ Pivotal Network Token .................................: 1edb78016b054bbaab960b3007a77b12-r
 ▪ Tanzu Demo Hube User ..................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .........................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ......................: aztkg
 ▪ AWS Route53 ZoneID ....................................: Z1X9T7571BMHB5
Azure Access Credentials
 ▪ Azure SubscriptionId ..................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Azure TennantId .......................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Azure Region ..........................................: westeurope
Verify Azure Application (TanzuDemoHub)
 ▪ Application ID ........................................: c26c9d99-646b-415a-83ca-17fb53827960
 ▪ Application Display Name ..............................: TanzuDemoHub
 ▪ ServicePrincipal ......................................: dac5e6d7-65a9-4402-add7-905f3c8a3e15
 ▪ Role Binding ..........................................: Owner
Verifing Azure Jump-Server (jump-aztkg.pcfsdu.com)
 ▪ SSH Command ...........................................: jump-aztkg.pcfsdu.com
----------------------------------------------------------------------------------------------------------------------------------------------
ssh -o StrictHostKeyChecking=no -o RequestTTY=yes -o ServerAliveInterval=240 -i /Users/sdu/.tanzu-demo-hub/KeyPair-Azure.pem ubuntu@52.166.176.113
----------------------------------------------------------------------------------------------------------------------------------------------
Configure Jump Server: 52.166.176.113
 ▪ Clone TDH GIT Repository ..............................: https://github.com/pivotal-sadubois/tanzu-demo-hub.git
 ▪ Verify SuDO Access for user ...........................: /etc/sudoers.d/ubuntu
Validate Certificates for domain (aztkg.pcfsdu.com)
 ▪ Certificate Expiratation Data: ........................: Sep 20 12:48:01 2021 GMT
Accepting Image Terms for Provider (vmware-inc) / Offer: (tkg-capi)
Creating TKG Managment Cluster
 ▪ Cluster Name ..........................................: tkgmc-azure-sadubois
 ▪ Configuration File ....................................: /home/ubuntu/.tanzu-demo-hub/config/tkgmc-azure-sadubois.yaml
 ▪ Control Plane Machine Type ............................: Standard_D2s_v3
 ▪ Worker Node Machine Type ..............................: Standard_D2s_v3
 ▪ Cluster CIDR ..........................................: 100.96.0.0/11
 ▪ Service CIDR ..........................................: 100.64.0.0/13
 ▪ Health Check Enabled ..................................: true
Create TKG Managment Cluster
 ▪ Cluster Name ..........................................: tkgmc-azure-sadubois
 ▪ Cluster Context .......................................: tkgmc-azure-sadubois-admin@tkgmc-azure-sadubois
 ▪ Cluster Config ........................................: ~/.tanzu-demo-hub/config/tkgmc-azure-sadubois.cfg
 ▪ Cluster Kubeconfig ....................................: ~/.tanzu-demo-hub/config/tkgmc-azure-sadubois.kubeconfig
Cleaning Up kubectl config
Create the TKG Management Cluster deployment File
 ▪ Deployment File .......................................: /Users/sdu/.tanzu-demo-hub/config/tkgmc-tkgmc-azure-sadubois.yaml
 ▪ Management Cluster ....................................: tkgmc-azure-sadubois
 ▪ Cloud Infrastructure ..................................: Azure
Create config file for TKG Workload Clusters
 ▪ Deployment File (dev) .................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-azure-sadubois-wc-dev.yaml
 ▪ Deployment File (prod) ................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-azure-sadubois-wc-prod.yaml
-----------------------------------------------------------------------------------------------------------
  NAME                         TYPE               ENDPOINT  PATH                                                                      CONTEXT                                                        
  tkgmc-vsphere-tkgm-sadubois  managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-vsphere-tkgm-sadubois.kubeconfig  tkgmc-vsphere-tkgm-sadubois-admin@tkgmc-vsphere-tkgm-sadubois  
  tkgmc-azure-sadubois         managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-azure-sadubois.kubeconfig         tkgmc-azure-sadubois-admin@tkgmc-azure-sadubois                
  tkg-mc                       managementcluster            /tmp/sacha.yaml                                                           tkg-mc-admin@tkg-mc                                            
-----------------------------------------------------------------------------------------------------------
1.) Check Management Cluster Status (On local workstation or on the jump server)
    => tanzu management-cluster get
    => kubectl config set-cluster tkgmc-azure-sadubois                                  # Set k8s Context to mc Cluster
    => kubectl config set-context tkgmc-azure-sadubois-admin@tkgmc-azure-sadubois       # Set k8s Context to mc Cluster
    => kubectl get cluster --all-namespaces                                             # Set k8s Context to the TKG Management Cluster
    => kubectl get kubeadmcontrolplane,machine,machinedeployment --all-namespaces       # To verify the first control plane is up
    => tanzu login --server tkgmc-azure-sadubois                                        # Show Tanzu Management Cluster
    => tanzu management-cluster get                                                     # Show Tanzu Management Cluster
2.) Ceeate TKG Workload Cluster
    => tanzu kubernetes-release get
    => tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-azure-sadubois-wc-dev.yaml  <cluster-name> -tkr v1.18.17---vmware.2-tkg.1
    => tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-azure-sadubois-wc-prod.yaml <cluster-name>
    => tanzu cluster kubeconfig get <cluster-name> --admin
    => tanzu cluster list --include-management-cluster
2.) Ceeate Tanzu Demo Hub (TDH) Workload Cluster with services (TBS, Harbor, Ingres etc.)
    => ./deployTKG -m tkgmc-azure-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-azure-sadubois
    => ./deployTKG -m tkgmc-azure-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-azure-sadubois -k "v1.17.16---vmware.2-tkg.1"
3.) Delete the Management Cluster
    => tanzu management-cluster delete tkgmc-azure-sadubois-sadubois -y
4.) Login to Jump Server: jump-aztkg.pcfsdu.com (only if required)
    => ssh -o StrictHostKeyChecking=no -o RequestTTY=yes -o ServerAliveInterval=240 -i /Users/sdu/.tanzu-demo-hub/KeyPair-Azure.pem ubuntu@52.166.176.113
```

# Tanzu-Demo-Hub on vSphere
This option will install a TKG Management Server (TKGm) on vSphere. Only the deployment on [VMware PEZ Cloud Service](https://pez-portal.int-apps.pcfone.io/ "VMware PEZ Cloud") is currently supported. The support for other vSphere envuronments is planned to a later time. 

## Deployment on VMware PEZ Cloud
The VMware PEZ Cloud is ideal for a TKG deployment as all compontents such as Jump Server, DHCP enabled networks etc. has been preconfigured for use. From the list of different deployment options choose the 'IaaS Only - vSphere (7.0 U2)' option. 

*Deployment Requirements*
- PEZ Environment - IaaS Only - vSphere (7.0 U2)
- AWS Route53 Domain (ie. pcfsdu.com)
- Macbook with Docker Desktop enabled

![PEZ](https://github.com/pivotal-sadubois/tanzu-demo-hub/blob/main/files/PEZ.png)
Take the values provided from the VMware PEZ Cloud environment details page and add them to your local $HOME/tanzu-demo-hub.cfg configuration file. If it does not yet exist, please create it.

*Tanzu Demo Hub Configuration ($HOME/.tanzu-demo-hub.cfg)*
```
##########################################################################################################
##################################### VSPHERE ENVIRONMENT PEZ (TKGm) #####################################
##########################################################################################################

VSPHERE_TKGM_DNS_DOMAIN=haas-505.pez.vmware.com
VSPHERE_TKGM_VCENTER_SERVER=vcsa-01.haas-505.pez.vmware.com
VSPHERE_TKGM_VCENTER_ADMIN=administrator@vsphere.local
VSPHERE_TKGM_VCENTER_PASSWORD=3Ezfgpmr47LI5aEisK!
VSPHERE_TKGM_JUMPHOST_NAME=ubuntu-505.haas-505.pez.vmware.com
VSPHERE_TKGM_JUMPHOST_USER=ubuntu
VSPHERE_TKGM_JUMPHOST_PASSWORD=3Ezfgpmr47LI5aEisK!
VSPHERE_TKGM_SSH_PRIVATE_KEY_FILE=$HOME/.tanzu-demo-hub/KeyPair-PEZ-private.pem
VSPHERE_TKGM_SSH_PUBLIC_KEY_FILE=$HOME/.tanzu-demo-hub/KeyPair-PEZ-public.pem
VSPHERE_TKGM_DATASTORE=LUN01
VSPHERE_TKGM_DATACENTER=Datacenter
VSPHERE_TKGM_CLUSTER=Cluster
VSPHERE_TKGM_NETWORK="Extra"
VSPHERE_TKGM_VMFOLDER="/Datacenter/vm"
VSPHERE_TKGM_SUBNET=10.212.153
VSPHERE_TKGM_CONTROL_PLANE_ENDPOINT=${VSPHERE_TKGM_SUBNET}.105
VSPHERE_TKGM_WORKLOAD_CLUSTER_IP_LIST="${VSPHERE_TKGM_SUBNET}.111 ${VSPHERE_TKGM_SUBNET}.112 ${VSPHERE_TKGM_SUBNET}.113 ${VSPHERE_TKGM_SUBNET}.114"
VSPHERE_TKGM_LOADBALANCER_IPPOOL="${VSPHERE_TKGM_SUBNET}.${VSPHERE_TKGM_SUBNET}.160"
VSPHERE_TKGM_MGMT_CLUSTER_CONTROL_PLANE=${VSPHERE_TKGM_SUBNET}.105
VSPHERE_TKGM_WKLD_CLUSTER01_CONTROL_PLANE=${VSPHERE_TKGM_SUBNET}.111
VSPHERE_TKGM_WKLD_CLUSTER01_LOADBALANCER_POOL=${VSPHERE_TKGM_SUBNET}.115-${VSPHERE_TKGM_SUBNET}.119
VSPHERE_TKGM_WKLD_CLUSTER02_CONTROL_PLANE=${VSPHERE_TKGM_SUBNET}.121
VSPHERE_TKGM_WKLD_CLUSTER02_LOADBALANCER_POOL=${VSPHERE_TKGM_SUBNET}.125-${VSPHERE_TKGM_SUBNET}.129
VSPHERE_TKGM_WKLD_CLUSTER03_CONTROL_PLANE=${VSPHERE_TKGM_SUBNET}.131
VSPHERE_TKGM_WKLD_CLUSTER03_LOADBALANCER_POOL=${VSPHERE_TKGM_SUBNET}.135-${VSPHERE_TKGM_SUBNET}.139
```
The following variables are required to access AWS Route53 to manage your DNS Domain and create Let's Enscript certificates used in the Tanzu Demo Hub demo's
```
##########################################################################################################
########################## AWS CREDENTIALS AND ROUTE53 DOMAIN CONFIGURATION  #############################
##########################################################################################################

export AWS_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXX"                        
export AWS_SECRET_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"    
export AWS_REGION="eu-central-1"
export AWS_HOSTED_DNS_DOMAIN="mydomain.com"  # YOUR PERSONAL DNS DOMAIN HOSTED ON ROUTE53
```



```
$ ./deployTKGmc
CONFIURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
-----------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg              AWS     awstkg  tkgmc-aws-<TDH_USER>           dev   tkgmc-aws.yaml
tkgmc-aws-prod.cfg             AWS     awstkg  tkgmc-aws-dev-<TDH_USER>       prod  tkgmc-aws-dev.yaml
tkgmc-azure-dev.cfg            Azure   aztkg   tkgmc-azure-<TDH_USER>         dev   tkgmc-azure.yaml
tkgmc-azure-prod.cfg           Azure   aztkg   tkgmc-azure-<TDH_USER>         prod  tkgmc-azure.yaml
tkgmc-dev-vsphere-macbook.cfg  vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-dev.cfg          vSphere vstkg   tkg-mc-vsphere-dev-<TDH_USER>  dev   tkgmc-dev-vsphere-macbook.yaml
tkgmc-vsphere-tkgm-dev.cfg     vSphere vstkg   tkgmc-vsphere-<TDH_USER>       dev   tkgmc-vsphere-tkgm.yaml
-----------------------------------------------------------------------------------------------------------
USAGE: ./deployTKGmc [oprions] <deployment>
            --delete                 # Delete Management Cluster and Jump Server
            --debug                  # default (disabled)  
            --native                 # Use 'native' installed tools instead of the tdh-tools container

./deployTKGmc tkgmc-vsphere-tkgm-dev.cfg

```


