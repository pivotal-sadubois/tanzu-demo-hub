# Tanzu Demo Hub - VMware Tanzu SQL with PostgreSQL

This demo package is to illustrate the capabilities of the **VMware Tanzu SQL with PostgreSQL for Kubernetes** and the Postgres operator. The individual demos gides trough the live cycle of a database deployment containing *deployment, backup/restore, upgdrading and integration into an application*. Some of the demos requires to be used in order as they are depending on heach other (see more in the requirements section in the demo description). 

*Featuring Demos*
- [Deploy a Single instance Database](#deploy-a-Single-instance-Database)
- [Deploy a High Available Database](#deploy-a-high-available-database)
- [Generate database load with pgbench](#generate-database-load-with-pgbench)
- [Create a Database Backup with pgbackrest](#create-a-database-backup-with-pgbackrest)
- [Database Resize CPU Memory and Disk](#database-resize-cpu-Memory-and-disk)
- [Deploy and Attach an Application](#deploy-and-attach-an-application)

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
Deploy a Single instance Database (tanzu-postgres-deploy-singleton)
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Minio S3 datasore will be created to host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl.png)](https://asciinema.org/a/IgerhydQM91apIPEI7dTRA2xl)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-deploy-singleton.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-deploy-singleton.cast
```

## Deploy a High Available Database
This demo is demonstrating the deployment of single instance PostgreSQL database on Kubernetes with the Postgres Operator. During the installation an Minio S3 datasore will be created to
 host the backup data (demonstrated in a seperated demo) and the PostgreSQL Tools (pgAdmin4) will be installed for the administration. 

[![asciicast](https://asciinema.org/a/5aET6ekFMllThGPAVHJtzwH2P.png)](https://asciinema.org/a/5aET6ekFMllThGPAVHJtzwH2P)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-deploy-ha.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-deploy-ha.cast
```

## Generate database load with pgbench
To test the performnace of the PostgreSQL database, we can generate load to it with pgbench. This can simulate multiple parallel user sessions and application access to the database. 

[![asciicast](https://asciinema.org/a/UfQ2SsP9sKLh9t330sgvkgE05.png)](https://asciinema.org/a/UfQ2SsP9sKLh9t330sgvkgE05)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-pgbench.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-pgbench.cast
```

## Create a database backup with pgbackrest
This demo demonstrations the backup of a PostgreSQL database with (pgbackrest) to S3 storagea. As backup target can be used any S3 Object Storage such as from 'Amazon AWS' or 'Minio S3'. For this demo we will use Minio S3 we have deployed on the same Kubernetes cluster.

[![asciicast](https://asciinema.org/a/kuIhu8OOvVU2HXuScOhvSEFdW.png)](https://asciinema.org/a/kuIhu8OOvVU2HXuScOhvSEFdW)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-pgbackrest.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-pgbackrest.cast
```

## Database Resize CPU Memory and Disk
In this demo we are going to resize the CPU, Memory and Storage capacity of a running PostgreSQL database instance. The Storage resize is depending on the StorageClass capabilities of the Cloud Storage provider. 

[![asciicast](https://asciinema.org/a/UUVG31qu2ttBNTK2rVujEySr6.png)](https://asciinema.org/a/UUVG31qu2ttBNTK2rVujEySr6)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-dbresize.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-deploy-dbresize.cast
```

## Deploy and Attach an Application
The final part of this demo is to deploy an application to kubernetes and attach it to our PostgreSQL database. We use the Sprint Music Demo application originaly build for CloudFoundry demos and package it into a docker container that we first push to the Harbor registry and then deploy it to the kubernetes environment. 

[![asciicast](https://asciinema.org/a/6HGnRnQJeFqcp4DouwH1yOdFU.png)](https://asciinema.org/a/6HGnRnQJeFqcp4DouwH1yOdFU)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tanzu-postgres-spring-music-app.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tanzu-postgres-spring-music-app.cast
```

