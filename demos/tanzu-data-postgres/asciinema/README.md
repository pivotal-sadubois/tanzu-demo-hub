# Tanzu Demo Hub - Demo Playback

The tanzu-demo-hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

*Recorded Demos*
- Deploy a Single instance Database (tanzu-postgres-deploy-singleton.cast.cast)
- Deploy a High Available Database (tanzu-postgres-deploy-ha.cast.cast)
- Generate Load to the database with pgbench (tanzu-postgres-pgbench.cast)
- Create a Database Backup to Minio S3 storage with pgbench (tanzu-postgres-pgbench.cast)
- Deploy an Application connecting to the PostgreSQL database (tanzu-postgres-spring-music-demo.cast)

*Deploy a Single instance Databse (tanzu-postgres-deploy-singleton.cast.cast)
The tanzu-demo-hub initiative is to build a environment to run predefined and tested Demos demonstration the capabilites of the VMware Tanzu production portfolio. The scripts and tools provided deploy TKG Management clusters on vSphere, AWS Cloud or Microsoft Azure cloud and on your local Labtop (Minikube) and installs standard services such as LoadBalancer, Ingress Routers, Harbor Registry, Mini S3 etc. The deployment scripts will create Let's Enscript certificates for you automaticly that all installed services and demos have valid certificates.

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Play the recorded demo in a teminal: 
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-singleton.cast.cast
```

