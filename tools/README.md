# Tanzu Demo Hub - TDH Tools Container


The TDH Tools container contain all the Tools and Utilities requires to operate and run Tanzu Demo Hub Environment and Demos. Each version of the TDH Tools Container contains its own version of tools depending on the environment (Tanzu Kubernetes Grid / Tanzu Comnunity Edition) and its Tanzu CLI Version. The have seperate config files (ie. $HOME/.tdh-tools-tce-1.4.1 or $HOME/.tdh-tools-tce-1.5.1).

*TDH Tools and Utilites*
The followin Tools and Utilities have been installed withing the TDH Tools Container. The major difference is the Tanzu CLI which differs in every version of the container.

| TDH Tools and Utilities | TKG 1.4.1, TKG 1.5.1, TCE 0.8.1, TCE 0.10.0 |
| --- | --- | 
| Tanzu Mission Control CLI | 0.42, 0.42, 0.42, 0.42 |
| Build Service Version | 1.4.2, 1.4.2, 1.4.2, 1.4.2 |
| Build Service Tools (kp) | 0.4.2, 0.4.2, 0.4.2, 0.4.2 |
| Tantzu CLI Bundle | 1.4.1, 1.4.1, 1.5.1, 0.9.1, 0.10.0 |
| Carvel Tools: - Handle multiple k8s Ressources (kapp) | 0.42.0, 0.42.0, 0.42.0, 0.42.0 |
| Carvel Tools: - Build/Reference container images (kbld) | 0.31.0, 0.31.0, 0.31.0, 0.31.0 | 
| Carvel Tools: - Template Overlay for k8s config (ytt) | 0.38.0, 0.38.0, 0.38.0, 0.38.0 |
| Carvel Tools: - Bundle and Relocate App Config (imgpkg) | 0.23.1, 0.23.1, 0.23.1, 0.23.1 |
| Hashicorp Terraform | 0.14.3, 0.14.3, 0.14.3, 0.14.3 |
| Local Kubernetes clusters (Kind) | 0.11.1, 0.11.1, 0.11.1, 0.11.1 |
| Kubernetes Cluster API (clusterctl) | v1.0.4, v1.0.4, v1.0.4, v1.0.4 |
| vSphere CLI (GOVC) | 0.27.2, 0.27.2, 0.27.2, 0.27.2 |
| Microsft Azure CLI (az) | latest, latest, latest, latest |
| Amazon AWS CLI (aws) | latest, latest, latest, latest |

*TDH Tools Environment Config (dotfiles)*
CertManager (Let's Enscript Wildcard Certificates)
This is a comment

*TDH Tools Container for Tanzu Kubernetes Grid (TKG) Files and Directories*

```
        $TDH_HOME/tools/tdh-tools/tdh-tools-tkg-${VERSION}          ## TDH Tools Container - Start script
        $TDH_HOME/tools/tdh-tools/tdh-tools-tkg-cleanup-${VERSION}  ## TDH Tools Container - Cleanup script
        $TDH_HOME/files/tdh-tools/tdh-tools-tkg-${VERSION}.cfg      ## TDH Tools Container (dotfiles) - Tools & Utility Versions
        $TDH_HOME/files/tdh-tools/Dockerfile-tkg-${VERSION}         ## TDH Tools Container Dockerfile
        /tmp/tdh-tools-tkg-${VERSION}                               ## TDH Tools Container - Docker Build Directory
        $HOME/.tdh-tools-tkg-${VERSION}                             ## TDH Tools Container - Tools & Utility Config (dotfiles) 
```

glaasdasd

```

$TDH_HOME/tools/tdh-tools/tdh-tools-tkg-${VERSION}          ## TDH Tools Container - Start script 
$TDH_HOME/tools/tdh-tools/tdh-tools-tkg-cleanup-${VERSION}  ## TDH Tools Container - Cleanup script
$TDH_HOME/files/tdh-tools/tdh-tools-tkg-${VERSION}.cfg      ## TDH Tools Container (dotfiles) - Tools & Utility Versions
$TDH_HOME/files/tdh-tools/Dockerfile-tkg-${VERSION}         ## TDH Tools Container Dockerfile
/tmp/tdh-tools-tkg-${VERSION}                               ## TDH Tools Container - Docker Build Directory
$HOME/.tdh-tools-tkg-${VERSION}                             ## TDH Tools Container - Tools & Utility Config (dotfiles) 

...

| Files | Description |
| --- | --- |
| $TDH_HOME/tools/tdh-tools/tdh-tools-tkg-${VERSION} | TDH Tools Container - Start script |
| $TDH_HOME/tools/tdh-tools/tdh-tools-tkg-cleanup-${VERSION} | TDH Tools Container (dotfiles) - Cleanup script |
| $TDH_HOME/files/tdh-tools/tdh-tools-tkg-${VERSION}.cfg | TDH Tools Container (dotfiles) - Tools & Utility Versions |
| $TDH_HOME/files/tdh-tools/Dockerfile-tkg-${VERSION}.cfg | TDH Tools Container Dockerfile |
| /tmp/tdh-tools-tkg-${VERSION} | TDH Tools Container - Docker Build Directory |
| $HOME/.tdh-tools-tkg-${VERSION} | TDH Tools Container - Tools & Utility Config (dotfiles) |

*TDH Tools Container for Tanzu Kubernetes Grid (TKG) Files and Directories*
| Files | Description |
| --- | --- |
| $TDH_HOME/tools/tdh-tools/tdh-tools-tce-${VERSION} | TDH Tools Container - Start script |
| $TDH_HOME/tools/tdh-tools/tdh-tools-tce-cleanup-${VERSION} | TDH Tools Container (dotfiles) |
| $TDH_HOME/files/tdh-tools/tdh-tools-tce-${VERSION}.cfg | TDH Tools Container (dotfiles) - Tools & Utility Versions |
| $TDH_HOME/files/tdh-tools/Dockerfile-tce-${VERSION}.cfg | TDH Tools Container Dockerfile |
| /tmp/tdh-tools-tce-${VERSION} | TDH Tools Container - Docker Build Directory |
| $HOME/.tdh-tools-tce-${VERSION} | TDH Tools Container - Tools & Utility Config (dotfiles) |

*TDH Tools Environment Config (dotfiles)*
The TDH Tools Container (dotfiles) represent a seperate configuration for all the Tools & Utilites installed in the container. These directories will be mounted from the users $HOME directory to the TDH Tools Container at Runtime. The TDH_TOOLS_PATH variable stands for the TDH Tools Container (.tdh-tools-tkg-${VERSION} or .tdh-tools-tce-${VERSION}).

| File/Directories | Description |
| --- | --- |
| $HOME/$TDH_TOOLS_PATH/.cache:$HOME/.cache | Cached Tanzu Confif |
| $HOME/$TDH_TOOLS_PATH/.config:$HOME/.config | Configuraiton for HELM and Tanzu |
| $HOME/$TDH_TOOLS_PATH/.kube:$HOME/.kube | Kubernetes / TKG Cluster Contexts |
| $HOME/$TDH_TOOLS_PATH/.kube-tkg:$HOME/.kube-tkg | Tanzu Management Cluster Contexts |
| $HOME/$TDH_TOOLS_PATH/.local:$HOME/.local | Tanzu CLI Config (.local/share/tanzucli) |
| $HOME/$TDH_TOOLS_PATH/.tanzu:$HOME/.tanzu | Tanzu Config (DEPRECATED) |
| $HOME/$TDH_TOOLS_PATH/.terraform:$HOME/.terraform | Terraform Configuration |
| $HOME/$TDH_TOOLS_PATH/.terraform.d:$HOME/.terraform.d | Terraform Configuration |
| $HOME/$TDH_TOOLS_PATH/.s3cfg:$HOME/.s3cfg | AWS S3 Contig |
| $HOME/$TDH_TOOLS_PATH/.govmomi:$HOME/.govmomi | GOVC Configuration |
| $HOME/$TDH_TOOLS_PATH/.gradle:$HOME/.gradle | Gradle Config |
| $HOME/$TDH_TOOLS_PATH/.docker:$HOME/.docker | Docker Login Credentials |
| $HOME/$TDH_TOOLS_PATH/.mvn:$HOME/.mvn | Mavan Config |
| $HOME/$TDH_TOOLS_PATH/.mc:$HOME/.mc | Minio Client Config |
| $HOME/$TDH_TOOLS_PATH/.aws:$HOME/.aws | Persistant AWS Login Credentials |
| $HOME/$TDH_TOOLS_PATH/.azure:$HOME/.azure | Microsoft Azure Login Credentials |
| $HOME/$TDH_TOOLS_PATH/.cluster-api:$HOME/.cluster-api | ClusterAPI (clusterctl) Configuration |
| $HOME/$TDH_TOOLS_PATH/.vmware-cna-saas:$HOME/.vmware-cna-saas | Tanzu Mission Contro (TMC) Login Credentials |
| $HOME/$TDH_TOOLS_PATH/tmp:/tmp | Keep the /tmp directory persistent |

This is a comment

| Files | Description |
| --- | --- |
| $TDH_HOME/tools/tdh-tools/tdh-tools-(tkg|tce)-${VERSION} | TDH Tools Container start script for Tanzu Kubernetes Grid (TKG) or Tanzu Comnunity Edition (TCE)
| $TDH_HOME/files/tdh-tools/tdh-tools-(tkg|tce)-${VERSION}.cfg | TDH Tools Container Configuration for Tanzu Kubernetes Grid (TKG) or Tanzu Comnunity Edition (TCE)
| $TDH_HOME/files/tdh-tools/Dockerfile-(tkg|tce)-${VERSION} | TDH Tools Container Dockerfile for Tanzu Kubernetes Grid (TKG) or Tanzu Comnunity Edition (TCE)


