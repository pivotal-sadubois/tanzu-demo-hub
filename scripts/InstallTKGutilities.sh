#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGutilities.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################

export TDHPATH=$1
export DHENV=$2
export DEBUG=$3
export LC_ALL=en_US.UTF-8

if [ -f $HOME/tanzu-demo-hub/functions ]; then
  . $HOME/tanzu-demo-hub/functions 
else
  echo "ERROR: TDH Functions ($HOME/tanzu-demo-hub/functions) not found"
  exit 1
fi

apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1

#installPackage docker.io
installSnap docker
systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1
usermod -aG docker ubuntu

if [ ! -f /usr/local/bin/vmw-cli ]; then
  messagePrint " - Install Package (vmw-cli)" "installing"
  docker run apnex/vmw-cli shell > vmw-cli 2>/dev/null
  mv vmw-cli /usr/local/bin
  chmod 755 /usr/local/bin/vmw-cli
fi

if [ ! -f /usr/local/bin/tanzu ]; then
  messagePrint " - Install Tanzu CLI" "installing"
  . ~/.tanzu-demo-hub.cfg
  export VMWUSER="$TDH_MYVMWARE_USER"
  export VMWPASS="$TDH_MYVMWARE_PASS"
  vmw-cli ls vmware_tanzu_kubernetes_grid > /dev/null 2>&1

  cnt=0
  vmwfile=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^tanzu-cli-bundle-linux" | tail -1 | awk '{ print $1 }')
  while [ "$vmwfile" == "" -a $cnt -lt 5 ]; do
    vmwfile=$(vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null | egrep "^tanzu-cli-bundle-linux" | tail -1 | awk '{ print $1 }')
    let cnt=cnt+1
    sleep 10
  done

  if [ "$vmwfile" == "" ]; then 
    echo "ERROR: failed to download $vmwfile"
    echo "       => export VMWUSER=\"$TDH_MYVMWARE_USER\""
    echo "       => export VMWPASS=\"$TDH_MYVMWARE_PASS\""
    echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
    exit 1
  else 
    cnt=0
    while [ ! -f "$vmwfile" -a $cnt -lt 10 ]; do
      vmw-cli ls vmware_tanzu_kubernetes_grid 2>/dev/null
      vmw-cli cp $vmwfile > /dev/null 2>&1

      let cnt=cnt+1
      sleep 30
    done

    if [ ! -f $vmwfile ]; then 
      echo "ERROR: failed to download $vmwfile"
      echo "       => export VMWUSER=\"$TDH_MYVMWARE_USER\""
      echo "       => export VMWPASS=\"$TDH_MYVMWARE_PASS\""
      echo "       => vmw-cli ls vmware_tanzu_kubernetes_grid"
      echo "       => (cd /tmp/; vmw-cli cp $vmwfile)" 
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
    tanzu plugin install --local cli all

    gunzip cli/*.gz
    mv cli/imgpkg-linux-amd64-* /usr/local/bin/imgpkg && chmod +x /usr/local/bin/imgpkg
    mv cli/kapp-linux-amd64-*   /usr/local/bin/kapp   && chmod +x /usr/local/bin/kapp
    mv cli/kbld-linux-amd64-*   /usr/local/bin/kbld   && chmod +x /usr/local/bin/kbld
    mv cli/ytt-linux-amd64-*    /usr/local/bin/ytt    && chmod +x /usr/local/bin/ytt
  fi
fi


# INSTALL KIND
messagePrint " - Install Kind Cluster" "installing"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64 2>/dev/null
chmod +x ./kind
mv kind /usr/local/bin

# --- INSTALL KUNEADM ---
installSnap kubeadm --classic

if [ "$TDHENV" == "vSphere" ]; then 
  if [ ! -f /usr/bin/ovftool ]; then 
    messagePrint " - Install ovftool" "installing"
    if [ -f $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle ]; then 
      echo -e "\n\n\nyes" | sudo nohup $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle
    else
      echo "ERROR: VMware ovtools not found, please download to tanzu-content-hub/software from: "
      echo "https://my.vmware.com/group/vmware/downloads/details?downloadGroup=OVFTOOL441&productId=734"
      exit 1
    fi
  fi
  
  installPackage golang-go
  installPackage gccgo-go
  echo "=> Install GOVC"
  #curl -L https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz --output govc_linux_amd64.gz > /dev/null 2>&1
  wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz 2>/dev/null 1>&2
  gunzip govc_linux_amd64.gz
  mv govc_linux_amd64 /usr/local/bin/govc
  chmod +x /usr/local/bin/govc
fi

messagePrint " - Upgrading Packages" "apt upgrade -y"
apt upgrade -y > /dev/null 2>&1

touch /tkg_software_installed

exit 0
