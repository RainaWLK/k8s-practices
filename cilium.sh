helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  --set ipam.operator.clusterPoolIPv4PodCIDRList='{10.100.0.0/16}' \
  --set ipam.operator.clusterPoolIPv4MaskSize=24


helm install cilium oci://quay.io/cilium/charts/cilium \
  --version 1.19.2 \
  --namespace kube-system \
  --set ipam.operator.clusterPoolIPv4PodCIDRList='{10.100.0.0/16}' \
  --set ipam.operator.clusterPoolIPv4MaskSize=24