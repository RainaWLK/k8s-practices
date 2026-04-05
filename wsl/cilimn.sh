#!/bin/bash
# in k8s admin client
POD_CIDR="10.100.0.0/16"

# CNI
helm install cilium oci://quay.io/cilium/charts/cilium \
  --version 1.19.2 \
  --namespace kube-system \
  --set ipam.operator.clusterPoolIPv4PodCIDRList='{'$POD_CIDR'}' \
  --set ipam.operator.clusterPoolIPv4MaskSize=24

# check CIDR
kubectl get ciliumnodes
