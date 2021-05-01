# Tanzu Demo Hub - VMware Tanzu SQL with PostgreSQL

This demo package is to illustrate the capabilities of the **VMware Tanzu SQL with PostgreSQL for Kubernetes** and the Postgres operator. The individual demos gides trough the live cycle of a database deployment containing *deployment, backup/restore, upgdrading and integration into an application*. Some of the demos requires to be used in order as they are depending on heach other (see more in the requirements section in the demo description). 

*Featuring Demos*
- [Deploy a Single instance Database *(tanzu-postgres-deploy-singleton)*](#Deploy-a-Single-instance-Database)
- Deploy a High Available Database *(tanzu-postgres-deploy-ha)*
- Generate Load to the database with pgbench *(tanzu-postgres-pgbench)*
- Create a Database Backup to Minio S3 storage with pgbench *(tanzu-postgres-pgbench)*
- Deploy an Application connecting to the PostgreSQL database *(tanzu-postgres-spring-music-demo)*

*Requirements:* This demo is part of the Tanzu Demo Hub platform and requires a Kubernetes cluster deployd with either (deployMinikube, deployTMC or deployTKG). 

### Automated Self Test
The demo comes with an self test feature which processes the individual steps of each demo automaticly. That will give you a guarante  that the demos will work in your environment.
```
$ ./tdh-demo-selftest.sh
Tanzu Demo Hub - Demo Self Testing Suite
by Sacha Dubois, VMware Inc,
-----------------------------------------------------------------------------------------------------------
Testing Demo (tanzu-data-postgres)
 - Tanzu Data for Postgres - Deploy a Single Instance Database .................................: completed
 - Tanzu Data for Postgres - Load Generation on the Database ...................................: completed
 - Tanzu Data for Postgres - Instance Backup (pgBackRest) to S3 (minio) ........................: completed
 - Tanzu Data for Postgres - Database Resize (CPU, Memory and Disk) ............................: completed
 - Tanzu Data for Postgres - Deploy a High Availability Database ...............................: completed
 - Tanzu Data for Postgres - Load Generation on the Database ...................................: completed
 - Tanzu Data for Postgres - Instance Backup (pgBackRest) to S3 (minio) ........................: completed
 - Tanzu Data for Postgres - Database Resize (CPU, Memory and Disk) ............................: completed
 - Tanzu Data for Postgres - Cleaning up Demo Environment in Namespace tanzu-data-postgres-demo : completed
```


## Deploy a Single instance Database
## Deploy a Single instance Database (tanzu-postgres-deploy-singleton)
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Minio S3 datasore will be created to host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-deploy-singleton.sh
```

Play the recorded 'asciinema' demo in a teminal:
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-singleton.cast
```

## Deploy a High Available Database *(tanzu-postgres-deploy-ha)*
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Minio S3 datasore will be created to
 host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/5aET6ekFMllThGPAVHJtzwH2P.png)](https://asciinema.org/a/5aET6ekFMllThGPAVHJtzwH2P)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-deploy-ha.sh
```

Play the recorded 'asciinema' demo in a teminal:
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-ha.cast
```


## Database Resize (CPU, Memory and Disk) *(tanzu-postgres-dbresize)*
In this demo we are going to resize the CPU, Memory and Storage capacity of a running PostgreSQL database instance. The Storage resize is depending on the StorageClass capabilities of the Cloud Storage provider. 

[![asciicast](https://asciinema.org/a/UUVG31qu2ttBNTK2rVujEySr6.png)](https://asciinema.org/a/UUVG31qu2ttBNTK2rVujEySr6)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-dbresize.sh
```

Play the recorded 'asciinema' demo in a teminal:
```
$ tdh-demo-playback.sh ./tanzu-postgres-deploy-dbresize.cast
```


- [Deploy a Single instance Database *(tanzu-postgres-deploy-singleton)*](#Deploy-a-Single-instance-Database)


