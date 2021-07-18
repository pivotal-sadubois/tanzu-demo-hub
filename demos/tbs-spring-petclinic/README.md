# Tanzu Demo Hub - VMware Tanzu SQL with PostgreSQL

This demo package is to illustrate the capabilities of the **VMware Tanzu SQL with PostgreSQL for Kubernetes** and the Postgres operator. The individual demos gides trough the live cycle of a database deployment containing *deployment, backup/restore, upgdrading and integration into an application*. Some of the demos requires to be used in order as they are depending on heach other (see more in the requirements section in the demo description). 

*Featuring Demos*
- [Build and deploy Spring Petclinic App on Harbor](#build-and-deploy-spring-petclinic-app-on-harbor)
- [Build and deploy Spring Petclinic App on docker.io](#build-and-deploy-spring-petclinic-app-on-docker.io)

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
```

## Build and deploy Spring Petclinic App on Harbor
This demo demonstrates the building and deployment of a the Spring Petclinic Application with the VMware Tanzu Build Service. The source code of the application relies on Github which is connected to the Tanhzu Build Service. On building of the application, the Tanzu Build Service download the application source code and all dependancies and build the applicaiton (ie. Maven or Gradle for Java). After build comletion a docker container with the applicaiton artifact will be created and uploaded to the Harbor Image Registry. From there the application will be deployed to the Tanzu Demo Hub Kubernetes Cluster. 

[![asciicast](https://asciinema.org/a/426014.png)](https://asciinema.org/a/426014)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tbs-pedclinic-harbor.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tbs-pedclinic-harbor..cast
```

## Build and deploy Spring Petclinic App on Docker
This demo demonstrates the building and deployment of a the Spring Petclinic Application with the VMware Tanzu Build Service. The source code of the application relies on Github which is connected to the Tanhzu Build Service. On building of the application, the Tanzu Build Service download the application source code and all dependancies and build the applicaiton (ie. Maven or Gradle for Java). After build comletion a docker container with the applicaiton artifact will be created and uploaded to the docker.io Image Registry. From there the application will be deployed to the Tanzu Demo Hub Kubernetes Cluster.

[![asciicast](https://asciinema.org/a/426014.png)](https://asciinema.org/a/426014)

Run the demo as interactice session, the commands are real and executed on your Kubernetes Cluster
```
$ ./tbs-pedclinic-harbor.sh
```

Play the recorded 'asciinema' demo in a teminal (no kubernetes cluster or tdh environment required)
```
$ ./tdh-demo-playback.sh asciinema/tbs-pedclinic-docker..cast
```


