# Tanzu Demo Hub - VMware Tanzu SQL with PostgreSQL

This demo package is to illustrate the capabilities of the **VMware Tanzu SQL with PostgreSQL for Kubernetes** and the Postgres operator. The individual demos gides trough the live cycle of a database deployment containing *deployment, backup/restore, upgdrading and integration into an application*. Some of the demos requires to be used in order as they are depending on heach other (see more in the requirements section in the demo description). 

*Featuring Demos*
- Deploy a Single instance Database *(tanzu-postgres-deploy-singleton)*
- Deploy a High Available Database *(tanzu-postgres-deploy-ha)*
- Generate Load to the database with pgbench *(tanzu-postgres-pgbench)*
- Create a Database Backup to Minio S3 storage with pgbench *(tanzu-postgres-pgbench)*
- Deploy an Application connecting to the PostgreSQL database *(tanzu-postgres-spring-music-demo)*

*Requirements:* This demo is part of the Tanzu Demo Hub platform and requires a Kubernetes cluster deployd with either (deployMinikube, deployTMC or deployTKG). 

## Deploy a Single instance Database *(tanzu-postgres-deploy-singleton)*
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Mini S3 datasore will be created to host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Play the recorded demo in a teminal: 
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-singleton.cast.cast
```

## Deploy a High Available Database *(tanzu-postgres-deploy-ha)*
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Mini S3 datasore will be created to
 host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Play the recorded demo in a teminal:
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-singleton.cast.cast
```

