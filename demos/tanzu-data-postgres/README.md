# Tanzu Demo Hub - Tanzu Data PostgreSQL

This demo package is to illustrate the capabilities of the **VMware Tanzu SQL with PostgreSQL for Kubernetes** and the Postgres operator. The individual demos gides trough the live cycle of a database deployment containing *deployment, backup/restore, upgdrading and integration into an application*. Some of the demos requires to be used in order as they are depending on heach other (see more in the requirements section in the demo description). 

*Available Demos*
- Deploy a Single instance Database *(tanzu-postgres-deploy-singleton.cast.sh)*
- Deploy a High Available Database *(tanzu-postgres-deploy-ha.cast.sh)*
- Generate Load to the database with pgbench *(tanzu-postgres-pgbench.sh)*
- Create a Database Backup to Minio S3 storage with pgbench *(tanzu-postgres-pgbench.sh)*
- Deploy an Application connecting to the PostgreSQL database *(tanzu-postgres-spring-music-demo.sh)*

*Requirements*
This demo is part of the Tanzu Demo Hub platform and requires a Kubernetes cluster deployd with either (deployMinikube, deployTMC or deployTKG). 

## Deploy a Single instance Databse (tanzu-postgres-deploy-singleton.cast.cast
The tanzu-demo-hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Play the recorded demo in a teminal: 
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-singleton.cast.cast
```

