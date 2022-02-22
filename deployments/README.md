# Tanzu Demo Hub - Deployment Files
There are two different deployment files within the Tanzu Demo Hub Environment. The **Tanzu Management Cluster Configuration** deployment files defines the Tanzu Management Cluster Configuration for (Azure, AWS, vSphere and Docker) environments, where the **Tanzu Demo Hub Configuration** defines the detail configuration of the TKG Workload cluster such as Kubernetes Version, Worker and Control Plance Nodes and Kubernetes Services such as (Harbor Registry, Contour Ingres, Kubeapps etc.). 
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

Tanzu Management Cluster Configuration
-----------------------------------------------------------------------------------------------------------------------------------
tkgmc-aws-dev.cfg                          ##  Tanzu Management Cluster on AWS Deployment Config (dev-template) 
tkgmc-aws-prod.cfg                         ##  Tanzu Management Cluster on AWS Deployment Config (prod-template) 
tkgmc-azure-dev.cfg                        ##  Tanzu Management Cluster on Azure Deployment Config (dev-template) 
tkgmc-azure-prod.cfg                       ##  Tanzu Management Cluster on Azure Deployment Config (prod-template) 
tkgmc-vsphere-dev.cfg                      ##  Tanzu Management Cluster on vSphere Service (TKGs) Deployment Config (dev-template) 
tcemc-docker-dev.cfg                       ##  Tanzu Management Cluster on docker (TCE) Deployment Config (dev-template) 

Tanzu Mission Control (TMC)  Management Cluster Configuration
-----------------------------------------------------------------------------------------------------------------------------------
tmc-aws-awshosted.cfg                      ##  TMC Management Cluster on AWS Deployment Config (dev-template)
```
