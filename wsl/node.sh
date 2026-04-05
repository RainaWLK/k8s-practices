#!/bin/bash

rm -f /etc/machine-id
rm -f /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure

ip addr add 172.27.190.222/20 dev eth0

# edit /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
# ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS --address=172.27.190.222 --healthz-bind-address=172.27.190.222

kubeadm reset -f

rm -rf /etc/cni/net.d
iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

systemctl stop kubelet
systemctl disable kubelet


kubeadm join 172.27.190.210:6443 --token k9ih1g.cr8g6yttj2dauv31 \
--discovery-token-ca-cert-hash sha256:6c9c64d9a77be7fe05e9b4a0c16a686e94d9c080b486ff8d161a31bb641ce7fd \
--ignore-preflight-errors=Port-10250         # for WSL2 environment, because it's not real standalone machine, port 10250 may be occupied by control plane
