# Tanzu Demo Hub

The tanzu-demo-hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

![TanzuDemoHub](./TanzuDemoHub.jpg)

*Platfomrm Servives installed by Tanzu Demo Hub*
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

*Predefined Demos*
- Kubernetes Pod Security
- TMC Policies
- TBS PetClinic Demo
- Tanzu Data Postgres

*Predefined Demos*

*Tanzu-Demo-Hub on Minikube (GA)
*Tanzu-Demo-Hub on vSphere (TechPreview)
*Tanzu-Demo-Hub on AWS (In Development)
*Tanzu-Demo-Hub on Azure (TechPreview)

*Requirements*
- AWS Route53 Domain (https://aws.amazon.com/route53)

Tanzu-Demo-Hub on Minikube
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
