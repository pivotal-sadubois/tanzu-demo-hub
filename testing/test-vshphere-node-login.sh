# ############################################################################################
# File: ........: test-vshphere-node-login.sh
# Language .....: bash
# Author .......: Sacha Dubois, VMware
# Description ..: Tanzu Demo Hub - Test vSphere Cluster Node Login
# ############################################################################################
[ "$(hostname)" != "tdh-tools" ] && echo "ERROR: Needs to run in a tdh-tools container" && exit

. ../functions
. $HOME/.tanzu-demo-hub.cfg

cfg=$(grep "TDH_TKGMC_SUPERVISORCLUSTER=$VSPHERE_TKGS_SUPERVISOR_CLUSTER" $HOME/.tanzu-demo-hub/config/*.cfg | \
      head -1 | awk -F: '{ print $1 }')

fil=$(grep "TDH_TKGMC_KUBECONFIG" $cfg | awk -F'=' '{ printf("$%s\n", $NF )}')
eval export KUBECONFIG=$fil

kubectl get virtualmachines -A -o json > /tmp/output.json
CLUSTERS=$(jq -r '.items[].metadata.labels | select(."capw.vmware.com/cluster.role" == "controlplane")."capw.vmware.com/cluster.name"' /tmp/output.json) 

for n in $CLUSTERS; do
  sec=$(kubectl get secrets ${n}-ssh-password -o json | jq -r '.data."ssh-passwordkey"' | base64 -d )
  printf "Cluster: %-55s SSH Password: %s\n"  $n $sec

  NODELIST=$(jq -r --arg key "$n" '.items[] | select(.spec.resourcePolicyName == $key).metadata.name' /tmp/output.json) 
  for node in $NODELIST; do
   ipa=$(jq -r --arg key "$node" '.items[] | select(.metadata.name == $key).status.vmIp' /tmp/output.json) 

   printf " - %-40s %-16s \n" $node $ipa 
   printf "   ssh -o StrictHostKeyChecking=no vmware-system-user@%s\n" "$ipa"

  done 
done

echo "export PATH=$PATH:/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/19/fs/usr/local/bin"
echo "export OPTS=\"--endpoints=127.0.0.1:2379 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key\""
echo "etcdctl \$OPTS member list"
echo "etcdctl \$OPTS member list --write-out json | jq"
echo "etcdctl \$OPTS endpoint health"
echo "etcdctl \$OPTS endpoint health --write-out json | jq"

echo "etcdctl \$OPTS snapshot save snapshotdb01"
echo "etcdctl \$OPTS get /registry --prefix=true --keys-only"
echo "etcdctl \$OPTS get /registry --prefix=true --keys-only"
exit

etcdctl $OPTS get /registry --prefix=true --keys-only | grep -v ^$  | awk -F'/' '{ if ($3 ~ /cattle.io/) {h[$3"/"$4]++} else { h[$3]++ }} END { for(k in h) print h[k], k }' | sort -nr

# etcd via pod
https://vineethac.blogspot.com/search/label/TKG?m=0
