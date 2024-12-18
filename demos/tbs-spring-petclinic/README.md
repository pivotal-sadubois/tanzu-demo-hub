# Tanzu Demo Hub - VMware Tanzu Build Service

Consistently create production-ready container images that run on Kubernetes and across clouds. Automate source-to-container workflows across all your development frameworks. This demo shows the capabilities for the Tanzu Build Service with an example of the Spring Petclinic Application. 

![Spring Petclinic](files/petclinic.png)

*Featuring Demos*
- [Build and deploy Spring Petclinic App on Harbor](#build-and-deploy-spring-petclinic-app-on-harbor)
- [Build and deploy Spring Petclinic App on docker](#build-and-deploy-spring-petclinic-app-on-docker)

*Requirements:* This demo is part of the Tanzu Demo Hub platform and requires a Kubernetes cluster deployd with either (deployMinikube, deployTMC or deployTKG). 

### Automated Self Test
The demo comes with an self test feature which processes the individual steps of each demo automaticly. That will give you a guarante  that the demos will work in your environment.
```
$ ./tdh-demo-selftest.sh
Tanzu Demo Hub - Demo Self Testing Suite
by Sacha Dubois, VMware Inc,
-----------------------------------------------------------------------------------------------------------
Testing Demo (tanzu-data-postgres)
 - Tanzu Build Service (TBS) - Build and deploy Spring Petclinic App on Harbor .................: completed
 - Tanzu Build Service (TBS) - Build and deploy Spring Petclinic App on Docker.io ..............: completed
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
$ ./tdh-demo-playback.sh asciinema/tbs-pedclinic-harbor.cast
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


