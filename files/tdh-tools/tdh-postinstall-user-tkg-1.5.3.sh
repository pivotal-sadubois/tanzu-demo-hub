#!/bin/bash

chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1

cnt=$(/usr/local/bin/tanzu plugin list | grep management-cluster | grep -c "not installed") 
[ $cnt -gt 0 ] && /usr/local/bin/tanzu plugin sync > /dev/null 2>&1

cnt=$(/usr/local/bin/tanzu plugin list | grep -c accelerator)
[ $cnt -eq 0 ] && cd /tanzu-tap && tanzu plugin install --local cli all

