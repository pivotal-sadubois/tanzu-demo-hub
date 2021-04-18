#!/bin/bash
# ############################################################################################
# File: ........: InstallTKGutilities.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Installation Tanzu TKG utilities on Jump Host
# ############################################################################################

TDHPATH=$1; cd /tmp
TDHENV=$2; cd /tmp

echo "=> Install TKG Extensions"
#mkdir -p $TDHPATH/extensions && cd $TDHPATH/extensions
#tar xfz $TDHPATH/software/tkg-extensions-manifests-v1.2.0-vmware.1.tar-2.gz
#sudo chown -R ubuntu:ubuntu $TDHPATH/extensions

installSnap() {
  PKG=$1
  OPT=$2

  echo "=> Install Package ($PKG)"
  snap list $PKG > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    cnt=0
    snap install $PKG $OPT > /dev/null 2>&1; ret=$?
    while [ $ret -ne 0 -a $cnt -lt 3 ]; do
      snap install $PKG $OPT> /dev/null 2>&1; ret=$?
      sleep 30
      let cnt=cnt+1
    done

    if [ $ret -ne 0 ]; then
      echo "ERROR: failed to install package $PKG"
      echo "       => snap install $PKG $PKG"
      exit 1
    fi
  fi
}

installPackage() {
  PKG=$1

  echo "=> Install Package ($PKG)"
  dpkg -s $PKG > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    apt install $PKG -y > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "ERROR: failed to install package $PKG"
      echo "       => apt install $PKG -y"
      exit 1
    fi
  fi
}

apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1

installPackage docker.io
systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1
usermod -aG docker ubuntu

if [ ! -f /usr/local/bin/vmw-cli ]; then
  echo "=> Install (vmw-cli)"
  docker run apnex/vmw-cli shell > vmw-cli 2>/dev/null
  mv vmw-cli /usr/local/bin
  chmod 755 /usr/local/bin/vmw-cli
fi

if [ ! -f /usr/local/bin/tanzu ]; then
  echo "=> Install Tanzu CLI"
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

  (cd /tmp/; vmw-cli cp $vmwfile > /dev/null 2>&1)
  cd /tmp; tar xf $vmwfile

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
echo "=> Install Kind Cluster"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64 2>/dev/null
chmod +x ./kind
mv kind /usr/local/bin

# --- INSTALL KUNEADM ---
installSnap kubeadm --classic

if [ "$TDHENV" == "vSphere" ]; then 
  if [ ! -f /usr/bin/ovftool ]; then 
    echo "=> Install ovftool"
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

echo "=> Upgrading Packages"
apt upgrade -y > /dev/null 2>&1

echo "=> Rebooting Jump Host"
touch /tkg_software_installed

exit 0
