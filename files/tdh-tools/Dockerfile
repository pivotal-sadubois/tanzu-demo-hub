# ############################################################################################
# File: ........: files/tdh-tools/Dockerfile
# Language .....: docker
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Dockerfile for tdh-tools container
# ############################################################################################

FROM ubuntu:20.04
MAINTAINER Sacha Dubois <sdubois@vmware.com>
ENV TZ="Europe/Zurich"
ARG UID GID USER TZ HOME VMWUSER VMWPASS TANZU_CLI START 
ADD $TANZU_CLI /tmp
ADD kubectl /usr/local/bin
ADD kp              /usr/local/bin
ADD mc              /usr/local/bin
ADD tmc             /usr/local/bin
ADD kubectl-vsphere /usr/local/bin
ADD kubectl         /usr/local/bin

# --- LOCAL TIME AND USER ---
RUN touch /tdh_tools_docker_container 
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone
RUN useradd -u $UID -g $GID -d $HOME $USER 
RUN groupadd docker
RUN usermod -a -G docker $USER
RUN usermod -a -G daemon $USER
RUN usermod -a -G root $USER

# --- INSTALL REQUIRED UBUNTU PACKAGES ---
RUN apt-get update -qq && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    lxc \
    software-properties-common \
    lsb-core \
    lsb-release \
    gnupg \
    iptables
RUN apt-get clean 

# --- INSTALL DOCKER ---
RUN curl -sSL https://get.docker.com/ | sh
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod g+x /usr/local/bin/wrapdocker 
VOLUME /var/lib/docker
CMD ["wrapdocker"]
#RUN curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-Linux-x86_64 -o /usr/bin/docker-compose 
#RUN chmod +x /usr/local/bin/docker-compose
#RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# --- IMPORT MICROSOFT SSL KEYS ---
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >> /etc/apt/trusted.gpg.d/microsoft.gpg
RUN add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"

# --- INSTALL HELM ---
RUN curl -sL https://baltocdn.com/helm/signing.asc | gpg --dearmor >> /etc/apt/trusted.gpg.d/baltocdn.gpg
RUN add-apt-repository "deb https://baltocdn.com/helm/stable/debian/ all main"
RUN apt-get install helm -y

RUN apt-get update && apt-get install -y \
    git vim azure-cli jq awscli 

# --- INSTALL TANZU UTILITIES ---
RUN install /tmp/cli/core/v*/tanzu-core-linux_amd64 /usr/local/bin/tanzu
RUN gunzip -q /tmp/cli/*.gz

RUN mv /tmp/cli/imgpkg-linux* /usr/local/bin/imgpkg && chmod a+x /usr/local/bin/imgpkg
RUN mv /tmp/cli/kapp-linux* /usr/local/bin/kapp && chmod a+x /usr/local/bin/kapp
RUN mv /tmp/cli/kbld-linux* /usr/local/bin/kbld && chmod a+x /usr/local/bin/kbld
RUN mv /tmp/cli/ytt-linux* /usr/local/bin/ytt && chmod a+x /usr/local/bin/ytt

# --- CLEANUP ---
RUN rm -rf /tmp/cli
CMD chmod g+rwx /var/run/docker.sock

