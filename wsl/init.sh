#!/bin/bash
# in contral plane
POD_CIDR="10.100.0.0/16"
SERVICE_CIDR="192.168.0.0/24"

kubeadm init --pod-network-cidr $POD_CIDR --service-cidr $SERVICE_CIDR





# Then you can join any number of worker nodes by running the following on each as root:
# kubeadm token list
# kubeadm token create --print-join-command
# kubeadm join 172.27.190.210:6443 --token k9ih1g.cr8g6yttj2dauv31 --discovery-token-ca-cert-hash sha256:6c9c64d9a77be7fe05e9b4a0c16a686e94d9c080b486ff8d161a31bb641ce7fd