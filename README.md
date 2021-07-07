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

./deployTKGmc tkgmc-aws--dev.cfg

```

# Tanzu-Demo-Hub on vSphere
This option will install a TKG Management Server (TKGm) on vSphere. Only the deployment on 'VMware PEZ Cloud Service' [VMware PEZ Cloud Service](https://pez-portal.int-apps.pcfone.io/ "Google's Homepage") is currently supported and 

## Requiremtents
*Prebuild Demos*
- Kubernetes Pod Security
- TMC Policies
- TBS PetClinic Demo
- Tanzu Data Postgres


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


