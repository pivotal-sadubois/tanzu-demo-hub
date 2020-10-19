#!/bin/bash
#https://docs.python-guide.org/dev/virtualenvs/

export PIVNET_TOKEN=$1
#LOC=$(locale 2>/dev/null | grep LC_CTYPE | sed 's/"//g' | awk -F= '{ print $2 }') 
#export LC_ALL=en_US.UTF-8
#export LC_ALL="$LOC"

[ -d /usr/share/X11/locale/en_US.UTF-8 ] && export LC_ALL=en_US.UTF-8

sudo 2>/dev/null  mkdir -p /usr/local /usr/local/bin

echo "Install Software on Jumphost"
echo "- Pivnet Token: $PIVNET_TOKEN"
echo "- Update GIT repo https://github.com/pivotal-sadubois/pcfconfig.git"
#(cd ~/pcfconfig; git fetch)

apt-get update > /dev/null 2>&1

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
  #sudo pip3 install certbot-dns-route53
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

if [ ! -x /usr/bin/cf ]; then 
  echo "- Install CF-CLI"
  wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
  echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
  apt-get update && apt-get install cf-cli -y > /dev/null 2>&1
fi

while  [ ! -x /usr/bin/gcloud ]; do 
  echo "- Install GCP SDK"
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
  apt-get install apt-transport-https ca-certificates -y > /dev/null 2>&1
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg 2>/dev/null | \
  sudo 2>/dev/null apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - 
  apt-get update && apt-get install google-cloud-sdk -y > /dev/null 2>&1
done

while  [ ! -x /usr/bin/om ]; do 
  echo "- Install OM"
  #sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo apt-key add -
  #sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
  #sudo apt-get update > /dev/null 2>&1
  #sudo apt-get install om -y  > /dev/null 2>&1
  wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add - 
  echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list > /dev/null
  apt-get update > /dev/null 2>&1
  apt-get install om -y  > /dev/null 2>&1
done

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
  wget -q https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
  unzip -q terraform_0.11.14_linux_amd64.zip
  mv terraform /usr/local/bin/
  #sudo apt-get install terraform -y
fi

if [ ! -x /usr/local/bin/pivnet ]; then 
  echo "- Installing Pivnet"
  wget -q -O pivnet github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && chmod a+x pivnet && sudo mv pivnet /usr/local/bin
fi

if [ ! -x /usr/bin/bin/pks ]; then 
  echo "- Installing PKS Utility from Pivnet"
  pivnet login --api-token=$PIVNET_TOKEN 2>/dev/null
  PRODUCT_VERSION=$(pivnet releases -p pivotal-container-service --format json | jq -r '.[].version' | head -1)
  PRODUCT_ID=`pivnet product-files -p pivotal-container-service -r $PRODUCT_VERSION --format json | jq -r '.[] | select(.aws_object_key | contains("product-files/pivotal-container-service/pks-linux-amd64")).id'`
  pivnet download-product-files -p pivotal-container-service -r $PRODUCT_VERSION -i $PRODUCT_ID
  FILE_NAME=$(pivnet product-files -p pivotal-container-service -r $PRODUCT_VERSION --format json | jq -r '.[] | select(.aws_object_key | contains("product-files/pivotal-container-service/pks-linux-amd64")).aws_object_key' | awk -F'/' '{ print $NF }')
  chmod a+x $FILE_NAME
  mv $FILE_NAME /usr/local/bin/pks
fi

if [ ! -x /snap/bin/helm ]; then 
  echo "- Installing Helm Utility"
  sudo snap install helm --classic >/dev/null 2>&1
  sudo ln -s /snap/bin/helm /usr/bin/helm
fi

if [ ! -x /usr/bin/docker ]; then
  apt-get install docker.io -y  > /dev/null 2>&1
fi

if [ ! -x /usr/local/bin/uaac ]; then
  sudo apt-get install ruby -y > /dev/null 2>&1
  sudo apt-get install ruby-dev -y > /dev/null 2>&1
  sudo gem install cf-uaac > /dev/null 2>&1
fi

touch  /jump_software_installed

