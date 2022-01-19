#!/bin/bash

chown -R $(id -u):$(id -g) $HOME > /dev/null 2>&1

/usr/local/bin/tanzu plugin list > /dev/null 2>&1; ret=$?
stt=$(/usr/local/bin/tanzu plugin list -o json | jq -r '.[] | select(.name == "management-cluster").status')
if [ $ret -ne 0 -o "$stt" == "not installed" ]; then
  cd /tanzu && tanzu plugin clean
  cd /tanzu && /usr/bin/nohup tanzu plugin install --local cli all > /tmp/nohup.oout
fi

exit 0
