#!/bin/bash

TDHPATH=$1; cd /tmp

# INSTALL TKG UTILITY
tar xfz $TDHPATH/software/tkg-linux-amd64-v1.2.0-vmware.1.tar.gz
#mv /usr/local/bin; chmod +x /usr/local/bin/tkg

mv tkg/imgpkg-linux-amd64-v0.2.0+vmware.1 /usr/local/bin/imgpkg && chmod +x /usr/local/bin/imgpkg
mv tkg/kapp-linux-amd64-v0.33.0+vmware.1  /usr/local/bin/kapp   && chmod +x /usr/local/bin/kapp
mv tkg/kbld-linux-amd64-v0.24.0+vmware.1  /usr/local/bin/kbld   && chmod +x /usr/local/bin/kbld
mv tkg/tkg-linux-amd64-v1.2.0+vmware.1    /usr/local/bin/tkg    && chmod +x /usr/local/bin/tkg
mv tkg/ytt-linux-amd64-v0.30.0+vmware.1   /usr/local/bin/ytt    && chmod +x /usr/local/bin/ytt

# INSTALL TKG EXTENSIONS
mkdir $TDHPATH/extensions && cd $TDHPATH/extensions
tar xfz $TDHPATH/software/tkg-extensions-manifests-v1.2.0-vmware.1.tar-2.gz
sudo chown -R ubuntu:ubuntu $TDHPATH/extensions

sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1
sudo apt install docker.io -y > /dev/null 2>&1
sudo systemctl start docker > /dev/null 2>&1
sudo systemctl enable docker > /dev/null 2>&1
sudo usermod -aG docker ubuntu

touch  /tkg_software_installed

sudo reboot
