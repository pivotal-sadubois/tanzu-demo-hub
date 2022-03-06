#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGutilities.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################

export TDHPATH=$1
export TDHENV=$2
export DEBUG=$3
export LC_ALL=en_US.UTF-8

if [ -f /home/ubuntu/.docker/config.json ]; then
  chown ubuntu:ubuntu /home/ubuntu/.docker/config.json
fi

if [ -f $HOME/tanzu-demo-hub/functions ]; then
  . $HOME/tanzu-demo-hub/functions 
else
  echo "ERROR: TDH Functions ($HOME/tanzu-demo-hub/functions) not found"
  exit 1
fi

# --- CHECK ENVIRONMENT VARIABLES ---
if [ -f ~/.tanzu-demo-hub.cfg ]; then
  . ~/.tanzu-demo-hub.cfg
fi

messagePrint " ▪ Login to Docker Registry" "$TDH_REGISTRY_DOCKER_NAME"
cnt=0; ret=1
while [ $ret -ne 0 -a $cnt -lt 5 ]; do
  docker login docker.io -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS > /dev/null 2>&1; ret=$?
  sleep 60
  let cnt=cnt+1
done

# --- VERIFY RATE-LIMIT ---
TOKEN=$(curl --user "$TDH_REGISTRY_DOCKER_USER:$TDH_REGISTRY_DOCKER_PASS" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" 2>/dev/null| jq -r .token)
rlm=$(curl --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest 2>/dev/null | grep "ratelimit-limit" | awk '{ print $NF }') 
rrm=$(curl --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest 2>/dev/null | grep "ratelimit-remaining" | awk '{ print $NF }') 
messagePrint " ▪ Docker Ratelimit:" "$rlm"
messagePrint " ▪ Docker Ratelimit Remaining:" "$rrm"

echo "docker login $TDH_REGISTRY_DOCKER_NAME -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS "
if [ $ret -ne 0 ]; then
  echo "ERROR: failed to login to docker"
  echo "       => docker login $TDH_REGISTRY_DOCKER_NAME -u $TDH_REGISTRY_DOCKER_USER -p $TDH_REGISTRY_DOCKER_PASS"
  exit
fi

if [ ! -s /usr/local/bin/vmw-cli ]; then
  messagePrint " ▪ Install Package (vmw-cli)" "installing"
  docker run apnex/vmw-cli shell > vmw-cli 2>/dev/null
  if [ $? -ne 0 ]; then 
    echo "ERROR: faileed to run vmw-cli docker container"
    echo "       => docker run apnex/vmw-cli shell > vmw-cli"
    exit 1
  fi

  mv vmw-cli /usr/local/bin
  chmod 755 /usr/local/bin/vmw-cli
  sudo chown -R ubuntu:ubuntu /home/ubuntu/.docker
fi

if [ ! -s /usr/local/bin/tanzu ]; then
  messagePrint " ▪ Install Tanzu CLI" "installing"

  export VMWUSER="$TDH_MYVMWARE_USER"
  export VMWPASS="$TDH_MYVMWARE_PASS"
  vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1

  cnt=0
  vmwfile=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^tanzu-cli-bundle" | grep "linux" | tail -1 | awk '{ print $1 }')
  while [ "$vmwfile" == "" -a $cnt -lt 5 ]; do
    vmwfile=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^tanzu-cli-bundle" | grep "linux" | tail -1 | awk '{ print $1 }')
    let cnt=cnt+1
    sleep 10
  done

  if [ "$vmwfile" == "" ]; then 
    echo "ERROR: failed to download repo vmware_tanzu_kubernetes_grid"
    echo "       => export VMWUSER=\"$TDH_MYVMWARE_USER\""
    echo "       => export VMWPASS=\"$TDH_MYVMWARE_PASS\""
    echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
    exit 1
  else 
    cnt=0
    while [ ! -f "$vmwfile" -a $cnt -lt 10 ]; do
      vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1
      vmw-cli cp $vmwfile > /dev/null 2>&1

      let cnt=cnt+1
      sleep 30
    done

    if [ ! -f $vmwfile ]; then 
      echo "ERROR: failed to download $vmwfile"
      echo "       => export VMWUSER=\"$TDH_MYVMWARE_USER\""
      echo "       => export VMWPASS=\"$TDH_MYVMWARE_PASS\""
      echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
      echo "       => vmw-cli cp $vmwfile" 
      exit 1
    else
      mv $vmwfile /tmp
      cd /tmp; tar xf $vmwfile
    fi
  fi

  if [ -d /tmp/cli ]; then
    (cd cli; sudo install core/v*/tanzu-core-linux_amd64 /usr/local/bin/tanzu)
    cd /tmp
    tanzu plugin clean

    tanzu plugin install --local cli all > /dev/null 2>&1; ret=$?
    if [ $ret -ne 0 ]; then
      tanzu plugin sync
    fi
 
    gunzip cli/*.gz
    mv cli/imgpkg-linux-amd64-* /usr/local/bin/imgpkg && chmod +x /usr/local/bin/imgpkg
    mv cli/kapp-linux-amd64-*   /usr/local/bin/kapp   && chmod +x /usr/local/bin/kapp
    mv cli/kbld-linux-amd64-*   /usr/local/bin/kbld   && chmod +x /usr/local/bin/kbld
    mv cli/ytt-linux-amd64-*    /usr/local/bin/ytt    && chmod +x /usr/local/bin/ytt
  fi
fi


# INSTALL KIND
messagePrint " ▪ Install Kind Cluster" "installing"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64 2>/dev/null
chmod +x ./kind
mv kind /usr/local/bin

# --- INSTALL KUNEADM ---
installSnap kubeadm --classic

if [ "$TDHENV" == "vSphere" ]; then 
  if [ ! -f /usr/bin/ovftool ]; then 
    messagePrint " ▪ Install ovftool" "installing"
    if [ -f $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle ]; then 
      echo -e "\n\n\nyes" | nohup $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle > /dev/null 2>&1
      if [ $? -ne 0 ]; then 
        echo "ERROR: Unable to install ovftool"
        echo "       => sudo $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundl"
        rm -f nohup.out
        exit
      fi
     rm -f nohup.out
    else
      echo "ERROR: VMware ovtools not found, please download to tanzu-content-hub/software from: "
      echo "https://my.vmware.com/group/vmware/downloads/details?downloadGroup=OVFTOOL441&productId=734"
      exit 1
    fi
  fi
  
  installPackage golang-go
  installPackage gccgo-go

  if [ ! -s /usr/bin/govc ]; then
    messagePrint " ▪ Install GOVC" "installing"
    wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz 2>/dev/null 1>&2
    gunzip govc_linux_amd64.gz

    mv govc_linux_amd64 /usr/local/bin/govc
    chmod +x /usr/local/bin/govc
  fi
fi

#messagePrint " ▪ Upgrading Packages" "apt upgrade -y"
#apt upgrade -y > /dev/null 2>&1
messagePrint " ▪ Update Packages" "apt upgrade -y"
apt update -y > /dev/null 2>&1
[ -f /home/ubuntu/.docker ] && chown -R ubuntu:ubuntu /home/ubuntu/.docker

# --- INSTALL TMC CLIENT ---
if [ ! -x /usr/local/bin/tmc ]; then
  API_TOKEN=$(tmcAPI_getToken $TMC_SERVICE_TOKEN)
  url=$(tmcAPI_getCliBinary $API_TOKEN $TMC_SERVER_URL linuxX64)
  wget -q $url -O /tmp/tmc

  mv /tmp/tmc /usr/local/bin
  sudo chmod a+x /usr/local/bin/tmc
fi

touch /tkg_software_installed

exit 0
