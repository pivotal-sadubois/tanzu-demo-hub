#!/bin/bash

export KUBECONFIG=/Users/sdu/.tanzu-demo-hub/deployments/tkgmc-vsphere-sdubois/tdh-kubernetes-devops-environment/kubeconfig_tdh-kubernetes-devops-environment.yaml

stb=$(kubectl -n employee-demo-blue logs $(kubectl get pods -n employee-demo-blue --no-headers -o custom-columns=":metadata.name") | grep -c "Completed 200 OK")
stg=$(kubectl -n employee-demo-green logs $(kubectl get pods -n employee-demo-green --no-headers -o custom-columns=":metadata.name") | grep -c "Completed 200 OK")

while [ 1 ]; do
  cnb=$(kubectl -n employee-demo-blue logs $(kubectl get pods -n employee-demo-blue --no-headers -o custom-columns=":metadata.name") | grep -c "Completed 200 OK")
  cng=$(kubectl -n employee-demo-green logs $(kubectl get pods -n employee-demo-green --no-headers -o custom-columns=":metadata.name") | grep -c "Completed 200 OK")

  let ttb=cnb-stb
  let ttg=cng-stg

  b=$(printf "%02d\n" $ttb)
  g=$(printf "%02d\n" $ttg)

  clear; /usr/local/bin/figlet -c -w 210 "BLUE>  $b / $g  <GREEN"
#  echo "                                                                                             Blue                Green"

  sleep 3
done
