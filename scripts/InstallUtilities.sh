#!/bin/bash
# ############################################################################################
# File: ........: InstallUtilities.sh 
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Installation utilities on Jump Host
# ############################################################################################

#https://docs.python-guide.org/dev/virtualenvs/

export PIVNET_TOKEN=$1
export DEBUG=$2
export LC_ALL=en_US.UTF-8

[ -d /usr/share/X11/locale/en_US.UTF-8 ] && export LC_ALL=en_US.UTF-8

if [ -f $HOME/tanzu-demo-hub/functions ]; then
  . $HOME/tanzu-demo-hub/functions
else
  echo "ERROR: TDH Functions ($HOME/tanzu-demo-hub/functions) not found"
  exit 1
fi

mkdir -p /usr/local /usr/local/bin

installPackage snapd
installPackage curl

if [ ! -f /usr/bin/docker ]; then 
  # 20. Nov sdubois moved from snapd to apt install docker
  apt-get install apt-transport-https ca-certificates curl software-properties-common -y > /dev/null 2>&1
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" > /dev/null 2>&1
  apt update > /dev/null 2>&1
  installPackage docker.io

  systemctl start docker
  systemctl enable docker
  chmod 777 /var/run/docker.sock

#  apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1
#  #installPackage docker.io
#  installSnap docker
#  ln -s /snap/bin/docker /usr/bin/docker

  groupadd docker > /dev/null 2>&1
  usermod -aG docker ubuntu
fi

if [ ! -x /usr/bin/az ]; then 
  # Download and install the Microsoft signing key
  curl -qsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor 2>/dev/null | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

  # Add the Azure CLI software repository (skip this step on ARM64 Linux distributions)
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
  apt-get update > /dev/null

  installPackage azure-cli
fi

if [ ! -x /usr/bin/certbot ]; then 
  snap install core; sudo snap refresh core > /dev/null 2>&1
  snap install --classic certbot > /dev/null 2>&1
  ln -s /snap/bin/certbot /usr/bin/certbot
fi
 
messagePrint " - Install Certbot Plugin" "certbot-dns-route53"
snap set certbot trust-plugin-with-root=ok
installPackage zip
installSnap certbot-dns-route53
echo "   ---------------------------------------------------------------------------------------------------------------"
certbot plugins 2>/dev/null | \
   awk 'BEGIN{h="Certbot Plugins:"}{ if($1 == "*"){ a=$2 }; if ($1 == "Description:"){ printf("   %-17s %-12s %s\n",h,a,$0);h="" }}' | \
   sed 's/Description://g'
echo "   ---------------------------------------------------------------------------------------------------------------"

# --- INSTALL PACKAGTES ---
installPackage zip
installPackage awscli
#installSnap kubectl --classic
installPackage jq

if [ ! -x /usr/local/bin/kubectl-vsphere ]; then
  cp $HOME/tanzu-demo-hub/software/vsphere-plugin-$(uname).zip /tmp
  unzip -d /tmp /tmp/vsphere-plugin-$(uname).zip > /dev/null 2>&1
  mv /tmp/bin/kubectl-vsphere /usr/local/bin
  mv /tmp/bin/kubectl /usr/local/bin
  chmod a+x /usr/local/bin/kubectl-vsphere /usr/local/bin/kubectl
fi

#if [ ! -x /usr/bin/zipinfo ]; then
#  echo "=> Install ZIP"
#  installPackage zip
#fi

#if [ ! -x /usr/bin/aws ]; then 
#  installPackage awscli
#    
#  #echo "=> Install AWS CLI"
#  #curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" 2>/dev/null
#  #unzip -q awscli-bundle.zip 
#  #./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws
#fi

#if [ ! -x /usr/bin/kubectl ]; then 
#  installSnap kubectl --classic
#
#  #echo "=> Install Kubectl"
#  #curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" > /dev/null 2>&1
#  #chmod +x ./kubectl
#  #mv ./kubectl /usr/local/bin/kubectl
#fi

#if [ ! -x /usr/bin/jq ]; then 
#  echo "=> Install JQ"
#  installPackage jq
#fi

if [ ! -x /usr/local/bin/pivnet ]; then 
  echo "=> Installing Pivnet"
  wget -q -O pivnet github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && chmod a+x pivnet && sudo mv pivnet /usr/local/bin
fi

if [ ! -x /snap/bin/helm ]; then 
  installSnap helm --classic
  [ ! -s /usr/bin/helm ] && sudo ln -s /snap/bin/helm /usr/bin/helm
fi

#if [ ! -x /snap/bin/yq ]; then
#  wget -q https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
#fi

if [ ! -f /etc/ntp.conf ]; then
  installPackage ntp
  systemctl restart ntp
fi

touch  /jump_software_installed
exit 0

