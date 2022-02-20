# Tanzu Demo Hub - Deployment Files

The Tanzu Demo Hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

```
Tanzu Demo Hub Configuration
-----------------------------------------------------------------------------------------------------------------------------------
tkg-tanzu-demo-hub-1.4.1.cfg               ##  Tanzu Demo Hub (TDH) Service Configuration on TKG-1.4.1 
tkg-tanzu-demo-hub-1.5.1.cfg               ##  Tanzu Demo Hub (TDH) Service Configuration on TKG-1.5.1 
tkg-tanzu-tap-demo-1.0.1.cfg               ##  Tanzu Applicaiton Platform (1.0.1) on TKG-1.5.1 
tce-tanzu-demo-hub-0.10.0.cfg              ##  Tanzu Demo Hub (TDH) Service Configuration on TCE-0.10.0 
tce-tanzu-demo-hub-0.9.1.cfg               ##  Tanzu Demo Hub (TDH) Service Configuration on TCE-0.9.1 
tce-tanzu-tap-demo-1.0.1.cfg               ##  Tanzu Applicaiton Platform (1.0.1) on TCE-0.10.0 
minikube-tanzu-demo-hub.cfg                ##  Minikube Deployment Configuration 

Tanzi Management Cluster Configuration
-----------------------------------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg                          ##  Tanzu Management Cluster on AWS Deployment Config (dev-template) 
tkgmc-aws-prod.cfg                         ##  Tanzu Management Cluster on AWS Deployment Config (prod-template) 
tkgmc-azure-dev.cfg                        ##  Tanzu Management Cluster on Azure Deployment Config (dev-template) 
tkgmc-azure-prod.cfg                       ##  Tanzu Management Cluster on Azure Deployment Config (prod-template) 
tkgmc-vsphere-dev.cfg                      ##  Tanzu Management Cluster on vSphere Service (TKGs) Deployment Config (dev-template) 
tcemc-docker-dev.cfg                       ##  Tanzu Management Cluster on docker (TCE) Deployment Config (dev-template) 
tmc-aws-awshosted.cfg                      ##  TMC Management Cluster on AWS Deployment Config (dev-template)x 
```
