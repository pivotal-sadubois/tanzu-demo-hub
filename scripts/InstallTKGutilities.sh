#!/bin/bash

TDHPATH=$1; cd /tmp
TDHENV=$2; cd /tmp

# INSTALL TKG UTILITY
TKG_ARCHIVE=$(ls -1 $TDHPATH/software/tkg-linux* | tail -1) 
tar xfz $TKG_ARCHIVE

ls -la ./tkg
if [ ! -d ./tkg ]; then 
  echo "ERROR: failed to unpack $TKG_ARCHIVE"
  echo "       tar xfz $TKG_ARCHIVE"
  exit
fi

mv tkg/imgpkg-linux-amd64-* /usr/local/bin/imgpkg && chmod +x /usr/local/bin/imgpkg
mv tkg/kapp-linux-amd64-*   /usr/local/bin/kapp   && chmod +x /usr/local/bin/kapp
mv tkg/kbld-linux-amd64-*   /usr/local/bin/kbld   && chmod +x /usr/local/bin/kbld
mv tkg/tkg-linux-amd64-*    /usr/local/bin/tkg    && chmod +x /usr/local/bin/tkg
mv tkg/ytt-linux-amd64-*    /usr/local/bin/ytt    && chmod +x /usr/local/bin/ytt

echo "grässeres archschloch"
exit
## INSTALL TKG EXTENSIONS
#mkdir -p $TDHPATH/extensions && cd $TDHPATH/extensions
#tar xfz $TDHPATH/software/tkg-extensions-manifests-v1.2.0-vmware.1.tar-2.gz
#sudo chown -R ubuntu:ubuntu $TDHPATH/extensions

sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1
sudo apt install docker.io -y > /dev/null 2>&1
sudo systemctl start docker > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1
sudo usermod -aG docker ubuntu

# INSTALL KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64 2>/dev/null
chmod +x ./kind
mv kind /usr/local/bin

echo "PWD:$PWD"

if [ "$TDHENV" == "vSphere" ]; then 
  if [ ! -f /usr/bin/ovftool ]; then 
    if [ -f $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle ]; then 
      echo -e "\n\n\nyes" | sudo nohup $TDHPATH/software/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle
    else
      echo "ERROR: VMware ovtools not found, please download to tanzu-content-hub/software from: "
      echo "https://my.vmware.com/group/vmware/downloads/details?downloadGroup=OVFTOOL441&productId=734"
      exit 1
    fi
  fi
  
  # INSTALL GOVC
  sudo apt install golang-go -y > /dev/null 2>&1
  sudo apt install gccgo-go -y > /dev/null 2>&1
  #curl -L https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz --output govc_linux_amd64.gz > /dev/null 2>&1
  wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz 2>/dev/null 1>&2
  gunzip govc_linux_amd64.gz
  sudo mv govc_linux_amd64 /usr/local/bin/govc
  chmod +x /usr/local/bin/govc
fi

touch  /tkg_software_installed

sudo reboot
