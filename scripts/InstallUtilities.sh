#!/bin/bash
#https://docs.python-guide.org/dev/virtualenvs/

export PIVNET_TOKEN=$1
#LOC=$(locale 2>/dev/null | grep LC_CTYPE | sed 's/"//g' | awk -F= '{ print $2 }') 
export LC_ALL=en_US.UTF-8
#export LC_ALL="$LOC"

[ -d /usr/share/X11/locale/en_US.UTF-8 ] && export LC_ALL=en_US.UTF-8

sudo 2>/dev/null  mkdir -p /usr/local /usr/local/bin

echo "Install Software on Jumphost"
echo "- Pivnet Token: $PIVNET_TOKEN"
sudo apt-get install curl -y

# APT-CLEANUP
#sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list
#sudo apt-get update > /dev/null 2>&1

if [ ! -x /usr/bin/az ]; then 
  echo "- Install AZ CLI"
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash > /dev/null 2>&1
fi

if [ ! -x /usr/bin/certbot ]; then 
  sudo apt install software-properties-common -y
  sudo apt-add-repository ppa:certbot/certbot -y
  sudo apt update -y
  sudo apt install certbot -y
  sudo apt-get install python-pip -y
  pip install certbot_dns_route53 
  pip install cryptography --upgrade
  #sudo apt install python3-pip -y

  sudo apt-get install python3-pip -y
  sudo pip3 install certbot --upgrade
  sudo pip3 install certbot-dns-route53
  #pip install --upgrade pip
fi

if [ ! -x /usr/bin/zipinfo ]; then
  echo "- Install ZIP"
  apt-get install zip -y  > /dev/null 2>&1
fi

if [ ! -x /usr/bin/aws ]; then 
  echo "- Install AWS CLI"

  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" 2>/dev/null
  unzip -q awscli-bundle.zip 
  sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/bin/aws

  #apt-get install awscli -y > /dev/null 2>&1
  #sudo apt install python3-pip -y
  #pip3 install --upgrade awscli
  #sudo -H pip3 install --upgrade awscli
fi

if [ ! -x /usr/bin/kubectl ]; then 
  echo "- Install Kubectl"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  apt-get install kubectl -y --allow-unauthenticated > /dev/null 2>&1
fi

if [ ! -x /usr/bin/jq ]; then 
  echo "- Install JQ"
  apt-get install jq -y  > /dev/null 2>&1
fi

if [ ! -x /usr/bin/terraform ]; then 
  echo "- Install Terraform"
  #wget -q https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
  #unzip -qn terraform_0.11.14_linux_amd64.zip
  #mv terraform /usr/local/bin/
  #sudo apt-get install terraform -y
fi

if [ ! -x /usr/local/bin/pivnet ]; then 
  echo "- Installing Pivnet"
  wget -q -O pivnet github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && chmod a+x pivnet && sudo mv pivnet /usr/local/bin
fi

if [ ! -x /snap/bin/helm ]; then 
  echo "- Installing Helm Utility"
  sudo apt install snapd -y  sudo ln -s /snap/bin/helm /usr/bin/helm

  sudo snap install helm --classic >/dev/null 2>&1
  [ ! -s /usr/bin/helm ] && sudo ln -s /snap/bin/helm /usr/bin/helm
fi

#if [ ! -x /usr/bin/docker ]; then
#  sudo apt-get install docker.io -y  > /dev/null 2>&1
#fi

touch  /jump_software_installed

