#!/bin/bash

if [ "$1" == "" ]; then 
  echo "tdh init"
  echo "tdh clean"
  echo "tdh git"
  echo "tdh tap"
fi

if [ "$1" == "init" ]; then 
  echo "✓ Fork repository https://github.com/sdubois-tapdemo/newsletter"
  echo "Y" | gh repo fork https://github.com/pivotal-sadubois/newsletter.git 
fi

if [ "$1" == "kc" -o "$1" == "c" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  kubectl config get-contexts; echo; yq -o json $KUBECONFIG | jq -r '.contexts[].name' | sed 's/^/kubectl config use-context /g'
fi

if [ "$1" == "clean" ]; then 
  gh repo delete sdubois-tapdemo/newsletter --yes 2>/dev/null
  [ -d $HOME/workspace/newsletter ] && rm -rf $HOME/workspace/newsletter
  tanzu services class-claims delete newsletter-db --namespace newsletter -y 2>/dev/null
fi

if [ "$1" == "git" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "git -C $HOME/workspace clone https://github.com/sdubois-tapdemo/newsletter.git"
  echo "https://github.com/sdubois-tapdemo/newsletter/blob/main/catalog/catalog-info.yaml"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "sc" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "tanzu service class list"
  echo "tanzu service class get postgresql-unmanaged"
  echo "tanzu service class-claim create newsletter-db --class postgresql-unmanaged --parameter storageGB=3 -n newsletter"
  echo "tanzu services class-claims get newsletter-db --namespace newsletter"
  echo "kubectl get pods -n $(kubectl get ns | grep newsletter-db | awk '{ print $1 }')"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

if [ "$1" == "tap" ]; then 
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo "tanzu apps workload apply --file $HOME/workspace/newsletter/newsletter-subscription/config/workload.yaml --namespace newsletter \\"
  echo "  --source-image harbor.apps.tap.tanzudemohub.com/library/newsletter --debug --yes \\"
  echo "  --local-path /Users/sdubois/workspace/newsletter/newsletter-subscription --live-update --tail --update-strategy replace "
  echo "tanzu apps workload tail newsletter-subscription --namespace newsletter --timestamp --since 1h"
  echo "tanzu apps workload get newsletter-subscription --namespace newsletter"
  echo "tanzu apps workload list -n newsletter"
  echo "tanzu apps workload get newsletter-subscription -n newsletter"
  echo "-------------------------------------------------------------------------------------------------------------------------------"
  echo ""
fi

