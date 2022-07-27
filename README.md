# Tanzu Demo Hub


The Tanzu Demo Hub initiative is to build an environment to run predefined and tested demos of the capabilities from the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud, Microsoft Azure cloud, or on your local Laptop (Minikube) and install standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3, etc. The deployment scripts will create Let's Encrypt certificates for you automatically that all installed services and demos have valid certificates.

![TanzuDemoHub](https://github.com/pivotal-sadubois/tanzu-demo-hub/blob/main/files/TanzuDemoHub.jpg)

*Platform Services installed by Tanzu Demo Hub*
- CertManager (Let's Encrypt Wildcard Certificates)
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

*Prebuilt Demos*
- Kubernetes Pod Security
- TMC Policies
- TBS PetClinic Demo
- Tanzu Data Postgres
- [Tanzu Data Postgres](https://github.com/pivotal-sadubois/tanzu-demo-hub/tree/main/demos/tanzu-data-postgres)

*Supported Environments*
- [Tanzu-Demo-Hub on Minikube](#tanzu-demo-hub-on-minikube)
- [Tanzu-Demo-Hub on vSphere](#tanzu-demo-hub-on-vsphere)
- [Tanzu-Demo-Hub on AWS](#tanzu-demo-hub-on-aws)
- [Tanzu-Demo-Hub on Azure](#tanzu-demo-hub-on-azure)
- [Tanzu-Demo-Hub on Docker](#tanzu-demo-hub-on-docker)

*Requirements*
- AWS Route53 Domain (https://aws.amazon.com/route53)
- Docker.io Account (https://docker.io)
- myVMware Account (https://myvmware.com)
- Pivotal Network Account (https://network.pivotal.io)
- GitHub Account (https://github.com)

# Tanzu-Demo-Hub on Minikube
As mentioned in the title Minikub is the base for the installation. Download [Minikube](https://kubernetes.io/de/docs/tasks/tools/install-minikube/ "Download Minikube") the Hypervisor VirtualBox is required. 

*Tanzu Demo Hub Configuration ($HOME/.tanzu-demo-hub.cfg)*
```
##########################################################################################################
########################## AWS CREDENTIALS AND ROUTE53 DOMAIN CONFIGURATION  #############################
##########################################################################################################

export AWS_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXX"
export AWS_SECRET_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_REGION="eu-central-1"
export AWS_HOSTED_DNS_DOMAIN="mydomain.com"  # YOUR PERSONAL DNS DOMAIN HOSTED ON ROUTE53
```
TDH Services such as Harbor, Tanzu Build Service or Tanzu Postgres etc. require access to depending services such as (GitHub, Docker, PivNET etc). You can use your existing credentials if you already have an account or you need to signup if you don't have one.
*Supported Environments*
- [GitHub Account SignUp](https://github.com/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home)
- [myVMware SignUp](https://my.vmware.com/web/vmware/registration)
- [VMware Container Registry SignUp](https://account.run.pivotal.io/z/uaa/sign-up)
- [Docker Registry SignUp](https://hub.docker.com/signup)
- [Pivotal Network API Token](https://login.run.pivotal.io/login)
- [VMware Cloud Credentials](https://console.cloud.vmware.com))
```
#########################################################################################################################
###################################################### TDH SERVICES #####################################################
#########################################################################################################################

export TDH_USER=sadubois                                 ## TAKE YOUR PIVOTAL OR VMWARE USERID
export TDH_MYVMWARE_USER='sadubois@pivotal.io'           ## myVMware Account to download TKG Software Packages
export TDH_MYVMWARE_PASS='XXXXXXXXXX'                    ## => SIGN-UP: https://my.vmware.com/web/vmware/registration
export TDH_REGISTRY_VMWARE_NAME=registry.pivotal.io      ## VMware Container Registry (required for TBS and Harbor)
export TDH_REGISTRY_VMWARE_USER=sadubois@pivotal.io      ## => SIGN-UP: https://account.run.pivotal.io/z/uaa/sign-up
export TDH_REGISTRY_VMWARE_PASS=XXXXXXXXX
export TDH_REGISTRY_DOCKER_NAME=docker.io                ## Docker Registry (required for TBS and Harbor)
export TDH_REGISTRY_DOCKER_USER=<docker-uid>             ## => SIGN-UP: https://hub.docker.com/signup
export TDH_REGISTRY_DOCKER_PASS=XXXXXXXXX
export TDH_GITHUB_USER=<github-user>                     ## Github Account (http://github.com)
export TDH_GITHUB_PASS=XXXXXXXXXX
export TDH_GITHUB_SSHKEY=~/.ssh/id_XXXXXXXX
export TDH_HARBOR_ADMIN_PASSWORD=XXXXXXXXXXXX
export PCF_PIVNET_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXX-r"  ## Pivnet APi Token (https://network.pivotal.io)
```
The integration of Tanzu Mission Control and Tanzu Observability requires you to have a VMware Cloud Account in the tanzu-emea (Organization ID: fea0ee4b-bbf6-4444-b1d6-e493597d46a4) as a prerequisite. The Workload Cluster created will be automatically integrated into Tanzu Observability (TO) after creation, therefore it's required that you provide TO access credentials as well. 
```
#########################################################################################################################
################################################ TANZU OBSERVABILITY ####################################################
#########################################################################################################################

export TDH_TANZU_OBSERVABILITY_API_TOKEN="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export TDH_TANZU_OBSERVABILITY_URL="https://vmware.wavefront.com"
export TDH_TANZU_DATA_PROTECTION_ARN="arn:aws:iam::XXXXXXXXXXXX:role/VMwareTMCProviderCredentialMgr"
export TDH_TANZU_DATA_PROTECTION_BACKUP_LOCATION="sadubois-aws-dp"
```
If an integration into Tanzu Mission Control is planned (recommended) your TMC credentials need to be specified also
```
#########################################################################################################################
################################################## TMC CREDENTIALS ######################################################
#########################################################################################################################

export TMC_ACCOUNT_NAME_AWS=sadubois-aws
export TMC_PROVISIONER_NAME=sadubois-aws
export TMC_SSH_KEY_NAME_AWS=tanzu-demo-hub
export TMC_SERVICE_TOKEN="45YWzUCd0ICo2ZKSKtJ9hEIlPuwWPma4C0d7RI2wS8y7AYE6H941as668Wqyi80F" #sadubois@pivoal.io
export TMC_CONTEXT_NAME=vmware-cloud-tmc
```


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
```

The Tanzu Demo Hub can be deployed with different deployment configurations. As default and a requirement to run the Tanzu Demo Hub Demos the (`minikube-tanzu-demo-hub.cfg`) is required to be used. Later this deployment can be modified and adjusted for your needs.
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
 ▪ Pivotal Network Token .....................................: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-r
 ▪ Tanzu Demo Hube User ......................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .............................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ..........................: 
 ▪ AWS Route53 ZoneID ........................................: XXXXXXXXXXXXXX
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
Harbor Registry
 ▪ Verify Harbor Registry .....................................: bitnami/harbor
   Harbor Registry Namespace: .................................: registry-harbor
   Harbor Registry Helm Chart: ................................: harbor-9.2.2
   Harbor Registry Version: ...................................: 2.1.2
   Harbor Registry Status: ....................................: deployed
   Harbor Registry Installed/Updated: .........................: 2021-06-08 01:09:25.175152 +0200 CEST
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
The Tanzu Demo Hub in the Microsoft Azure Cloud is divided into two parts, the installation of the Management Cluster which is done by the deployTKGmc utility and the deployment of the TKG Cluster and installation of the Kubernetes services such as (Harbor, Tanzu Build Serice, Tanzu Data Postgres etc.) will be installed with the deployTKG afterward.

*Tanzu Demo Hub Configuration ($HOME/.tanzu-demo-hub.cfg)*
```
#########################################################################################################################
############################################### AZURE CREDENTIALS #######################################################
#########################################################################################################################

export AZURE_SUBSCRIPTION_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export AZURE_TENANT_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export AZURE_LOCATION="westeurope"
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
If an integration into Tanzu Mission Control is planned (recommended) your TMC credentials need to be specified also
```
#########################################################################################################################
################################################## TMC CREDENTIALS ######################################################
#########################################################################################################################

export TMC_ACCOUNT_NAME_AWS=sadubois-aws
export TMC_PROVISIONER_NAME=sadubois-aws
export TMC_SSH_KEY_NAME_AWS=tanzu-demo-hub
```

```
$ ./deployTKGmc
CONFIGURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
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

```
The Tanzu Demo Hub can be deployed with different deployment configurations. There are two precomfigured deployment files tkgmc-vsphere-tkgm-dev.cfg and tkgmc-vsphere-tkgm-prod.cfg which only differs in single node control-plance (dev) and a redundant (AZ Aware) Control Plance (prod).
```
./deployTKGmc tkgmc-vsphere-tkgm-dev.cfg
$ ./deployTKGmc tkgmc-vsphere-tkgm-dev.cfg 

Tanzu Demo Hub - Deploy TKG Management Cluster
by Sacha Dubois, VMware Inc,
----------------------------------------------------------------------------------------------------------------------------------------------
TDH Tools Docker Container (tdh-tools)
 ▪ Dockerfile Checksum (files/tdh-tools/Dockerfile) ......: 7796
 ▪ Docker Image (tdh-tools) Checksum .....................: 7796 => No Rebuild required
 ▪ Running TDH Tools Docker Container ....................: tdh-tools:latest /Users/sdu/workspace/tanzu-demo-hub/deployTKGmc tkgmc-vsphere-tkgm-dev.cfg
Cleaning Up kubectl config
Supporting services access (Pivotal Network, AWS Route53)
 ▪ Pivotal Network Token .................................: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-r
 ▪ Tanzu Demo Hube User ..................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .........................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ......................: vstkg
 ▪ AWS Route53 ZoneID ....................................: XXXXXXXXXXXXXX
vSphere Access Credentials
 ▪ vCenter Server Name ...................................: vcsa-01.haas-505.pez.vmware.com
 ▪ vCenter Admin User ....................................: administrator@vsphere.local
 ▪ vCenter Admin Password ................................: XXXXXXXXXXXXXXXXXXX
 ▪ TKG Management Cluster IP .............................: 10.212.153.105
 ▪ Jump Host Name ........................................: ubuntu-505.haas-505.pez.vmware.com
 ▪ Jump Host User ........................................: ubuntu
 ▪ SSH Private Key .......................................: /Users/sdu/.tanzu-demo-hub/KeyPair-PEZ-private.pem
 ▪ SSH Public Key ........................................: /Users/sdu/.tanzu-demo-hub/KeyPair-PEZ-public.pem
 ▪ TKG Management Custer Control Plane ...................: 10.212.153.105
 ▪ TKG Workload Cluster 01 ...............................: NAME_TAG: TKG_CLUSTER_01
 ▪     Cluster Control Plane .............................: 10.212.153.111
 ▪     LoadBalancer IP Pool ..............................: 10.212.153.115-10.212.153.119
 ▪ TKG Workload Cluster 02 ...............................: NAME_TAG: TKG_CLUSTER_02
 ▪     Cluster Control Plane .............................: 10.212.153.121
 ▪     LoadBalancer IP Pool ..............................: 10.212.153.125-10.212.153.129
 ▪ TKG Workload Cluster 03 ...............................: NAME_TAG: TKG_CLUSTER_03
 ▪     Cluster Control Plane .............................: 10.212.153.131
 ▪     LoadBalancer IP Pool ..............................: 10.212.153.135-10.212.153.139
Verify vSphere Jump-Server (ubuntu-505.haas-505.pez.vmware.com)
 ▪ Wait for SSH to be ready ..............................: < 3m
Verify SuDO Access ubuntu-505.haas-505.pez.vmware.com
 ▪ SSH Command ...........................................: ubuntu-505.haas-505.pez.vmware.com
----------------------------------------------------------------------------------------------------------------------------------------------
ssh -i /Users/sdu/.tanzu-demo-hub/KeyPair-PEZ-private.pem ubuntu@ubuntu-505.haas-505.pez.vmware.com
----------------------------------------------------------------------------------------------------------------------------------------------
Configure Jump Server: ubuntu-505.haas-505.pez.vmware.com
 ▪ Clone TDH GIT Repository ..............................: https://github.com/pivotal-sadubois/tanzu-demo-hub.git
 ▪ Verify SuDO Access for user ...........................: /etc/sudoers.d/ubuntu
Install Certificate for domain (vstkg.pcfsdu.com)
Validate Certificates for domain (vstkg.pcfsdu.com)
 ▪ Certificate Expiratation Data: ........................: Sep 12 05:46:27 2021 GMT
Verify Software Downloads from http://my.vmware.com
Uploading OVS Images to vSphere
Create the TKG Management Cluster deployment File
 ▪ Deployment File .......................................: /Users/sdu/.tanzu-demo-hub/config/tkgmc-tkgmc-vsphere-tkgm-sadubois.yaml
 ▪ Management Cluster ....................................: tkgmc-vsphere-tkgm-sadubois
 ▪ Cloud Infrastructure ..................................: vSphere
Create config file for TKG Workload Clusters
 ▪ Deployment File (dev) .................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-vsphere-tkgm-sadubois-wc-dev.yaml
 ▪ Deployment File (prod) ................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-vsphere-tkgm-sadubois-wc-prod.yaml
-----------------------------------------------------------------------------------------------------------
  NAME                         TYPE               ENDPOINT  PATH                                                                      CONTEXT                                                        
  tkgmc-vsphere-tkgm-sadubois  managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-vsphere-tkgm-sadubois.kubeconfig  tkgmc-vsphere-tkgm-sadubois-admin@tkgmc-vsphere-tkgm-sadubois  
  tkgmc-azure-sadubois         managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-azure-sadubois.kubeconfig         tkgmc-azure-sadubois-admin@tkgmc-azure-sadubois                
  tkg-mc                       managementcluster            /tmp/sacha.yaml                                                           tkg-mc-admin@tkg-mc                                            
-----------------------------------------------------------------------------------------------------------
1.) Check Management Cluster Status (On local workstation or on the jump server)
    => tanzu management-cluster get
    => kubectl config set-cluster tkgmc-vsphere-tkgm-sadubois                           # Set k8s Context to mc Cluster
    => kubectl config set-context tkgmc-vsphere-tkgm-sadubois-admin@tkgmc-vsphere-tkgm-sadubois # Set k8s Context to mc Cluster
    => kubectl get cluster --all-namespaces                                             # Set k8s Context to the TKG Management Cluster
    => kubectl get kubeadmcontrolplane,machine,machinedeployment --all-namespaces       # To verify the first control plane is up
    => tanzu login --server tkgmc-vsphere-tkgm-sadubois                                 # Show Tanzu Management Cluster
    => tanzu management-cluster get                                                     # Show Tanzu Management Cluster
2.) Create TKG Workload Cluster
    TKG Workload Cluster 01 ...............................: NAME_TAG: TKG_CLUSTER_01
        Cluster Control Plane .............................: 10.212.153.111
        LoadBalancer IP Pool ..............................: 10.212.153.115-10.212.153.119
    TKG Workload Cluster 02 ...............................: NAME_TAG: TKG_CLUSTER_02
        Cluster Control Plane .............................: 10.212.153.121
        LoadBalancer IP Pool ..............................: 10.212.153.125-10.212.153.129
    TKG Workload Cluster 03 ...............................: NAME_TAG: TKG_CLUSTER_03
        Cluster Control Plane .............................: 10.212.153.131
        LoadBalancer IP Pool ..............................: 10.212.153.135-10.212.153.139

    => export CLUSTER_NAME=<cluster_name>                   ## Workload Cluster Name
    => export VSPHERE_CONTROL_PLANE_ENDPOINT=<ip-address>   ## Control Plane IP Adress for the worklaod Cluster
    => tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-vsphere-tkgm-sadubois-wc-dev.yaml --tkr v1.20.4---vmware.3-tkg.1
    => tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-vsphere-tkgm-sadubois-wc-prod.yaml
    => tanzu cluster kubeconfig get $CLUSTER_NAME --admin
    => kubectl config use-context ${CLUSTER_NAME}-admin@$CLUSTER_NAME
    => tanzu cluster list --include-management-cluster
    => tanzu cluster delete $CLUSTER_NAME -y
2.) Ceeate Tanzu Demo Hub (TDH) Workload Cluster with services (TBS, Harbor, Ingres etc.)
    => ./deployTKG -m tkgmc-vsphere-tkgm-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-vsphere-sadubois -tag TKG_CLUSTER_01
    => ./deployTKG -m tkgmc-vsphere-tkgm-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-vsphere-sadubois -tag TKG_CLUSTER_02 -k "v1.17.16---vmware.2-tkg.1"
3.) Delete the Management Cluster
    => tanzu management-cluster delete tkgmc-vsphere-tkgm-sadubois-sadubois -y
4.) Login to Jump Server: ubuntu-505.haas-505.pez.vmware.com (only if required)
    => ssh -i /Users/sdu/.tanzu-demo-hub/KeyPair-PEZ-private.pem ubuntu@ubuntu-505.haas-505.pez.vmware.com


```

# Tanzu-Demo-Hub on Azure
```
$ ./deployTKGmc
CONFIGURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
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
 ▪ Pivotal Network Token .................................: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-r
 ▪ Tanzu Demo Hube User ..................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .........................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ......................: aztkg
 ▪ AWS Route53 ZoneID ....................................: XXXXXXXXXXXXXX
Azure Access Credentials
 ▪ Azure SubscriptionId ..................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Azure TennantId .......................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Azure Region ..........................................: westeurope
Verify Azure Application (TanzuDemoHub)
 ▪ Application ID ........................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Application Display Name ..............................: TanzuDemoHub
 ▪ ServicePrincipal ......................................: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 ▪ Role Binding ..........................................: Owner
Verifying Azure Jump-Server (jump-aztkg.pcfsdu.com)
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
Create TKG Management Cluster
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

# Tanzu-Demo-Hub on AWS
```
$ ./deployTKGmc
CONFIGURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
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
```

```
$ ./deployTKGmc tkgmc-aws-dev.cfg 

Tanzu Demo Hub - Deploy TKG Management Cluster
by Sacha Dubois, VMware Inc,
----------------------------------------------------------------------------------------------------------------------------------------------
TDH Tools Docker Container (tdh-tools)
 ▪ Dockerfile Checksum (files/tdh-tools/Dockerfile) ..........: 3776
 ▪ Docker Image (tdh-tools) Checksum .........................: 3776 => No Rebuild required
 ▪ Running TDH Tools Docker Container ........................: tdh-tools:latest /Users/sdu/workspace/tanzu-demo-hub/deployTKGmc tkgmc-aws-dev.cfg
Cleaning Up kubectl config
Supporting services access (Pivotal Network, AWS Route53)
 ▪ Pivotal Network Token .....................................: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-r
 ▪ Tanzu Demo Hube User ......................................: sadubois
 ▪ AWS Route53 Hosted DNS Domain .............................: pcfsdu.com
 ▪ AWS Route53 Hosted DNS SubDomain ..........................: awstkg
 ▪ AWS Route53 ZoneID ........................................: XXXXXXXXXXXXXX
AWS Access Credentials
 ▪ AWS AccwssKey .............................................: XXXXXXXXXXXXXXXXXXXX
 ▪ AWS SecretKey .............................................: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 ▪ AWS Region ................................................: eu-central-1
 ▪ AWS Primary Availability Zone .............................: eu-central-1a
SSH Key Pairs
 ▪ KeyPair Name ..............................................: tanzu-demo-hub
 ▪ KeyPair File ..............................................: /Users/sdu/.tanzu-demo-hub/KeyPair-tanzu-demo-hub-eu-central-1.pem
 ▪ Verify KeyPair Fingerprint ................................: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
OIDC Identity Management (IdM)
 ▪ OKTA SecretId .............................................: XXXXXXXXXXXXXXXXXXXXX
 ▪ OKTA Client Secret ........................................: XXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXX
 ▪ OKTA URL ..................................................: https://vmware-tdh.okta.com
 ▪ OKTA Scopes ...............................................: openid,groups,email
 ▪ OKTA Group Claim ..........................................: groups
 ▪ OKTA Username Claim .......................................: code
AWS Jump-Server (jump-awstkg.pcfsdu.com)
 ▪ Cleaning up leftover terraform deployments ................: /Users/sdu/.tanzu-demo-hub/terraform/aws
 ▪ Deploy vSphere Jump-Server with (terraforms) ..............: jump-awstkg.pcfsdu.com
 ▪ Creating Variable file ....................................: /Users/sdu/.tanzu-demo-hub/terraform/aws/terraform.tfvars
 ▪ Terraform (init) ..........................................: /Users/sdu/.tanzu-demo-hub/terraform/aws
 ▪ Terraform (plan) ..........................................: /Users/sdu/.tanzu-demo-hub/terraform/aws
 ▪ Terraform (apply) .........................................: /Users/sdu/.tanzu-demo-hub/terraform/aws
 ▪ DNS Zone (pcfsdu.com: .....................................: zone managed by route53
 ▪ Updating Zone Record for (jump-awstkg.pcfsdu.com) .........: 18.193.88.227
 ▪ Updating Zone Record for (jump-awstkg.pcfsdu.com) .........: 18.193.88.227
 ▪ Updating Zone Record for (jump.awstkg.pcfsdu.com) .........: 18.193.88.227
Verify AWS Jump-Server
 ▪ AWS Instance ID ...........................................: i-XXXXXXXXXXXXXXXXX
 ▪ Jump Server Hostname ......................................: jump-awstkg.pcfsdu.com
 ▪ Jump Server Status ........................................: running
 ▪ Jump Server IP Address ....................................: 18.193.88.227
 ▪ Destroy Command ...........................................: terraform destroy
----------------------------------------------------------------------------------------------------------------------------------------------
terraform -chdir=/Users/sdu/.tanzu-demo-hub/terraform/aws destroy \
          -state=/Users/sdu/.tanzu-demo-hub/terraform/aws/terraform_awstkg.tfstate \
          -var-file=/Users/sdu/.tanzu-demo-hub/terraform/aws/terraform_awstkg.tfvars -auto-approve
----------------------------------------------------------------------------------------------------------------------------------------------
 ▪ Wait for SSH to be ready ..................................: < 5m
 ▪ SSH Command ...............................................: jump-awstkg.pcfsdu.com
----------------------------------------------------------------------------------------------------------------------------------------------
ssh -i /Users/sdu/.tanzu-demo-hub/KeyPair-tanzu-demo-hub-eu-central-1.pem ubuntu@jump-awstkg.pcfsdu.com
----------------------------------------------------------------------------------------------------------------------------------------------
Configure Jump Server: jump-awstkg.pcfsdu.com
 ▪ Clone TDH GIT Repository ..................................: https://github.com/pivotal-sadubois/tanzu-demo-hub.git
 ▪ Verify SuDO Access for user ...............................: /etc/sudoers.d/ubuntu
Install CLI Utilities (aws,az,gcp,bosh,pivnet,cf,om,jq) on Jump Host (jump.awstkg.pcfsdu.com)
 ▪ Verify Package (snapd) ....................................: 2.48.3+18.04
 ▪ Verify Package (curl) .....................................: 7.58.0-2ubuntu3.13
 ▪ Install Package (docker) ..................................: installing
 ▪ Install Package (azure-cli) ...............................: installing
core 16-2.51.1 from Canonical* installed
snap "core" has no updates available
certbot 1.17.0 from Certbot Project (certbot-eff*) installed
 - Install Certbot Plugin ......................................: certbot-dns-route53
 ▪ Install Package (zip) .....................................: installing
 ▪ Install Package (certbot-dns-route53) .....................: installing
   ---------------------------------------------------------------------------------------------------------------
   Certbot Plugins:  apache        Apache Web Server plugin
                     dns-route53   Obtain certificates using a DNS TXT record (if you are using AWS
                     nginx         Nginx Web Server plugin
                     standalone    Spin up a temporary webserver
                     webroot       Place files in webroot directory
   ---------------------------------------------------------------------------------------------------------------
 ▪ Verify Package (zip) ......................................: 3.0-11build1
 ▪ Install Package (awscli) ..................................: installing
 ▪ Install Package (jq) ......................................: installing
=> Installing Pivnet
 ▪ Install Package (helm) ....................................: installing
 ▪ Install Package (ntp) .....................................: installing
 ▪ Rebooting Jump Server .....................................: wait for services coming up ...
Install TKG Utilities (tkg, ytt, kapp, kbld, kubectl, kind) on Jump Host (jump.awstkg.pcfsdu.com)
 ▪ Login to Docker Registry ..................................: docker.io
 ▪ Docker Ratelimit: .........................................: 200;w=21600
 ▪ Docker Ratelimit Remaining: ...............................: 200;w=21600
docker login docker.io -u sadubois -p 000Penwin 
 ▪ Install Package (vmw-cli) .................................: installing
 ▪ Install Tanzu CLI .........................................: installing
chown: cannot access '/home/ubuntu/.docker': No such file or directory
 ▪ Install Kind Cluster ......................................: installing
 ▪ Install Package (kubeadm) .................................: installing
 ▪ Upgrading Packages ........................................: apt upgrade -y
Install Certificate for domain (awstkg.pcfsdu.com)
Validate Certificates for domain (awstkg.pcfsdu.com)
 ▪ Certificate Expiratation Data: ............................: Oct  2 22:15:37 2021 GMT
Creating TKG Management Cluster
 ▪ Cluster Name ..............................................: tkgmc-aws-sadubois
 ▪ Configuration File ........................................: ${HOME}/.tanzu-demo-hub/config/tkgmc-aws-sadubois.yaml
 ▪ Cluster CIDR ..............................................: 100.96.0.0/11
 ▪ Service CIDR ..............................................: 100.64.0.0/13
 ▪ Health Check Enabled ......................................: true
 ▪ Management Cluster Creating ...............................: This may take up to 15min ...
 ▪ Management Cluster Creating Completed .....................: /tmp/tkgmc-aws-sadubois.log
Cleaning Up kubectl config
Cleaning up old kubeconfig definitions
 ▪ TMC ReRegister Cluster ....................................: tkgmc-aws-sadubois
 ▪ TMC ReRegister Cluster failed, deregister .................: tkgmc-aws-sadubois
 ▪ TMC Register Cluster ......................................: tkgmc-aws-sadubois
 ▪ Install TMC Agent in Namespace ............................: vmware-system-tmc
Create the TKG Management Cluster deployment File
 ▪ Deployment File ...........................................: /Users/sdu/.tanzu-demo-hub/config/tkgmc-tkgmc-aws-sadubois.yaml
 ▪ Management Cluster ........................................: tkgmc-aws-sadubois
 ▪ Cloud Infrastructure ......................................: AWS
Create config file for TKG Workload Clusters
 ▪ Deployment File (dev) .....................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-aws-sadubois-wc-dev.yaml
 ▪ Deployment File (prod) ....................................: ~/.tanzu/tkg/clusterconfigs/tkgmc-aws-sadubois-wc-prod.yaml
-----------------------------------------------------------------------------------------------------------
  NAME                      TYPE               ENDPOINT  PATH                                                                   CONTEXT                                                  
  tkgmc-aws-sadubois        managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-aws-sadubois.kubeconfig        tkgmc-aws-sadubois-admin@tkgmc-aws-sadubois              
  tkgmc-azure-sadubois      managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-azure-sadubois.kubeconfig      tkgmc-azure-sadubois-admin@tkgmc-azure-sadubois          
  tkgmc-azure-dev-sadubois  managementcluster            /Users/sdu/.tanzu-demo-hub/config/tkgmc-azure-dev-sadubois.kubeconfig  tkgmc-azure-dev-sadubois-admin@tkgmc-azure-dev-sadubois  
-----------------------------------------------------------------------------------------------------------
1.) Check Management Cluster Status (On local workstation or on the jump server)
    => tanzu management-cluster get
    => kubectl config set-cluster tkgmc-aws-sadubois                                    # Set k8s Context to mc Cluster
    => kubectl config set-context tkgmc-aws-sadubois-admin@tkgmc-aws-sadubois           # Set k8s Context to mc Cluster
    => kubectl get cluster --all-namespaces                                             # Set k8s Context to the TKG Management Cluster
    => kubectl get kubeadmcontrolplane,machine,machinedeployment --all-namespaces       # To verify the first control plane is up
    => tanzu login --server tkgmc-aws-sadubois                                          # Show Tanzu Management Cluster
    => tanzu management-cluster get                                                     # Show Tanzu Management Cluster
2.) Ceeate TKG Workload Cluster
    => tools/tdh-tools.sh
       tdh-tools:/$ tanzu kubernetes-release get
       tdh-tools:/$ tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-aws-sadubois-wc-dev.yaml  <cluster-name> -tkr v1.18.17---vmware.2-tkg.1
       tdh-tools:/$ tanzu cluster create -f $HOME/.tanzu/tkg/clusterconfigs/tkgmc-aws-sadubois-wc-prod.yaml <cluster-name>
       tdh-tools:/$ tanzu cluster kubeconfig get <cluster-name> --admin
       tdh-tools:/$ tanzu cluster list --include-management-cluster
       tdh-tools:/$ exit
2.) Ceeate Tanzu Demo Hub (TDH) Workload Cluster with services (TBS, Harbor, Ingres etc.)
    => ./deployTKG -m tkgmc-aws-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-aws-sadubois
    => ./deployTKG -m tkgmc-aws-sadubois -d tkg-tanzu-demo-hub.cfg -n tdh-aws-sadubois -k "v1.17.16---vmware.2-tkg.1"
3.) Delete the Management Cluster (Local or on the Jump host)
    => tools/tdh-tools.sh
       tdh-tools:/$ tanzu management-cluster delete tkgmc-aws-sadubois -y
       tdh-tools:/$ exit
    => ssh -i /Users/sdu/.tanzu-demo-hub/KeyPair-tanzu-demo-hub-eu-central-1.pem ubuntu@jump-awstkg.pcfsdu.com
       tanzu management-cluster delete tkgmc-aws-sadubois -y
4.) Login to Jump Server: jump-awstkg.pcfsdu.com (only if required)
    => ssh -i /Users/sdu/.tanzu-demo-hub/KeyPair-tanzu-demo-hub-eu-central-1.pem ubuntu@jump-awstkg.pcfsdu.com
```

# Tanzu-Demo-Hub on vSphere
This option will install a TKG Management Server (TKGm) on vSphere. Only the deployment on [VMware PEZ Cloud Service](https://pez-portal.int-apps.pcfone.io/ "VMware PEZ Cloud") is currently supported. The support for other vSphere environments is planned for a later time. 

## Deployment on VMware H20 Cloud
The VMware H2O Environment is ideal for a TKG deployment as all components such as Jump Server, DHCP enabled networks etc. has been preconfigured for use. From the list of different deployment options choose the 'IaaS Only - vSphere (7.0 U3)' option.

*Deployment Requirements*
- H2O Environment - (vSphere with Tanzu - AVI - vSphere (7.0.3)
- AWS Route53 Domain (ie. pcfsdu.com)
- MacBook with Docker Desktop enabled

![H2O](https://github.com/pivotal-sadubois/tanzu-demo-hub/blob/main/files/H2O.png)
Take the values provided from the VMware H2O environment details page and add them to your local $HOME/tanzu-demo-hub.cfg configuration file. If it does not yet exist, please create it.

```
##########################################################################################################
##################################### VSPHERE ENVIRONMENT PEZ (TKGs) #####################################
##########################################################################################################
# For registerTMCmc H2o (vSphere with Tanzu - AVI - vSphere (7.0.3)) - tdh-sdubois-tap - expire Jul 29, 2022, 9:43:11 PM
VSPHERE_TKGS_VCENTER_SERVER=https://vc01.h2o-4-935.h2o.vmware.com	
VSPHERE_TKGS_VCENTER_ADMIN=administrator@vsphere.local
VSPHERE_TKGS_VCENTER_PASSWORD='u5_1UGbOajvc9xgNNBL'
VSPHERE_TKGS_SUPERVISOR_CLUSTER=vc01cl01-wcp.h2o-4-935.h2o.vmware.com
VSPHERE_TKGS_SUPERVISOR_STORAGE_POLICY=vc01cl01-t0compute
VSPHERE_TKGS_SUPERVISOR_STORAGE_CLASS=vc01cl01-t0compute
VSPHERE_TKGS_DNS_SERVER="10.79.2.5:53"
```

## Deployment on VMware PEZ Cloud
The VMware PEZ Cloud is ideal for a TKG deployment as all components such as Jump Server, DHCP enabled networks etc. has been preconfigured for use. From the list of different deployment options choose the 'IaaS Only - vSphere (7.0 U2)' option. 

*Deployment Requirements*
- PEZ Environment - IaaS Only - vSphere (7.0 U2)
- AWS Route53 Domain (ie. pcfsdu.com)
- MacBook with Docker Desktop enabled

![PEZ](https://github.com/pivotal-sadubois/tanzu-demo-hub/blob/main/files/PEZ.png)
Take the values provided from the VMware PEZ Cloud environment details page and add them to your local $HOME/tanzu-demo-hub.cfg configuration file. If it does not yet exist, please create it.

*Tanzu Demo Hub Configuration ($HOME/.tanzu-demo-hub.cfg)*
```
##########################################################################################################
##################################### VSPHERE ENVIRONMENT PEZ (TKGs) #####################################
##########################################################################################################

VSPHERE_TKGS_VCENTER_SERVER=pacific-vcsa.haas-505.pez.vmware.com
VSPHERE_TKGS_VCENTER_ADMIN=administrator@vsphere.local
VSPHERE_TKGS_VCENTER_PASSWORD=E95AVveIF3aONpAgKi!
VSPHERE_TKGS_SUPERVISOR_CLUSTER=wcp.haas-505.pez.vmware.com 
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
TDH Services such as Harbor, Tanzu Build Service or Tanzu Postgres etc. require access to depending services such as (GitHub, Docker, PivNET etc). You can use your existing credentials if you already have an account or you need to signup if you don't have one. 
*Supported Environments*
- [GitHub Account SignUp](https://github.com/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home)
- [myVMware SignUp](https://my.vmware.com/web/vmware/registration)
- [VMware Container Registry SignUp](https://account.run.pivotal.io/z/uaa/sign-up)
- [Docker Registry SignUp](https://hub.docker.com/signup)
```
#########################################################################################################################
###################################################### TDH SERVICES #####################################################
#########################################################################################################################

export TDH_USER=sadubois                                 ## TAKE YOUR PIVOTAL OR VMWARE USERID
export TDH_MYVMWARE_USER='sadubois@pivotal.io'           ## myVMware Account to download TKG Software Packages
export TDH_MYVMWARE_PASS='XXXXXXXXXX'                    ## => SIGN-UP: https://my.vmware.com/web/vmware/registration
export TDH_REGISTRY_VMWARE_NAME=registry.pivotal.io      ## VMware Container Registry (required for TBS and Harbor)
export TDH_REGISTRY_VMWARE_USER=sadubois@pivotal.io      ## => SIGN-UP: https://account.run.pivotal.io/z/uaa/sign-up
export TDH_REGISTRY_VMWARE_PASS=XXXXXXXXX
export TDH_REGISTRY_DOCKER_NAME=docker.io                ## Docker Registry (required for TBS and Harbor)
export TDH_REGISTRY_DOCKER_USER=<docker-uid>             ## => SIGN-UP: https://hub.docker.com/signup
export TDH_REGISTRY_DOCKER_PASS=XXXXXXXXX
export TDH_GITHUB_USER=<github-user>                     ## Github Account (http://github.com)
export TDH_GITHUB_PASS=XXXXXXXXXX
export TDH_GITHUB_SSHKEY=~/.ssh/id_XXXXXXXX
export TDH_HARBOR_ADMIN_PASSWORD=XXXXXXXXXXXX
export PCF_PIVNET_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXX-r"  ## Pivnet APi Token (https://network.pivotal.io)
```
Your TKG Management and Workload cluster should be integrated into Tanzu Observability automatically on creation, therefore its required that you provide TO access credentials as well
```
#########################################################################################################################
################################################ TANZU OBSERVABILITY ####################################################
#########################################################################################################################

export TDH_TANZU_OBSERVABILITY_API_TOKEN="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export TDH_TANZU_OBSERVABILITY_URL="https://vmware.wavefront.com"
export TDH_TANZU_DATA_PROTECTION_ARN="arn:aws:iam::XXXXXXXXXXXX:role/VMwareTMCProviderCredentialMgr"
export TDH_TANZU_DATA_PROTECTION_BACKUP_LOCATION="sadubois-aws-dp"
```
If an integration into Tanzu Mission Control is planned (recommended) your TMC credentials need to be specified also
```
#########################################################################################################################
################################################## TMC CREDENTIALS ######################################################
#########################################################################################################################

export TMC_ACCOUNT_NAME_AWS=sadubois-aws
export TMC_PROVISIONER_NAME=sadubois-aws
export TMC_SSH_KEY_NAME_AWS=tanzu-demo-hub
export TMC_SERVICE_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 
export TMC_CONTEXT_NAME=vmware-cloud-tmc
```
Tanzu Kubernetes Grid recommends the integration in either LDAP or OIDC Identity Provider. LDAP will be configured and installed on the Jump Server where 
OIDC requires an external Identity Provider such as OKTA. A free account can be obtained under https://okta.com
```
#########################################################################################################################
######################################### IDENTITY MANAGEMENT (OIDC/LDAP) ###############################################
#########################################################################################################################

export TDH_OKTA_SECRET_ID="=xxxxxxxxxxxxxxxxxxxx""
export TDH_OKTA_CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export TDH_OKTA_URL="https://mydomain.okta.com"
export TDH_OKTA_SCOPES="openid,groups,email"
export TDH_OKTA_USERNAME_CLAIM="code"
export TDH_OKTA_GROUP_CLAIM="groups"
```



```
$ ./deployTKGmc
CONFIGURATION                   CLOUD   DOMAIN  MGMT-CLUSTER                   PLAN  CONFIGURATION
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

