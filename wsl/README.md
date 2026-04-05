# Install K8s Cluster in WSL2 Environment (Windows)

This repository documents the end-to-end procedure for deploying a multi-node Kubernetes cluster within a Windows environment using **WSL2**. By leveraging separate WSL2 distributions as nodes, we achieve a high-fidelity cluster experience (Control Plane + Workers) with minimal resource overhead.

## 🌐 Network Architecture

The cluster uses a specific IP addressing scheme to prevent routing overlaps between the Windows Host, the WSL2 bridge, and the Kubernetes internal networks.

| Component         | CIDR Range         | Managed By           |
| :---------------- | :----------------- | :------------------- |
| **Node CIDR** | Dynamic (WSL2)     | Windows WSL2 Service |
| **Pod CIDR** | `10.100.0.0/16`    | Cilium CNI (eBPF)    |
| **Service CIDR** | `192.168.0.0/16`   | Kubernetes API       |

---

## 🏗️ Cluster Architecture

### 1. Prerequisites (Windows Side)
* **WSL2 Enabled:** Windows 11 with a kernel version supporting eBPF (5.10+).
* **Resource Tuning:** Create `%UserProfile%\.wslconfig` to manage global resource limits:
  ```ini
  [wsl2]
  memory=8GB
  processors=4
  ```

### 2. The "Golden Image" Preparation
We start with a single **Ubuntu 24.04** distribution to install all base components required by both the Control Plane and Worker nodes.

**A. OS and Kernel Configuration:**
```bash
# Enable IPv4 Forwarding and Bridge filtering
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter
```

**B. Container Runtime (containerd):**
```bash
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# CRITICAL: Enable SystemdCgroup for Ubuntu 24.04/Cgroup v2 compatibility
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

**C. Kubernetes Binaries:**
```bash
# Add Kubernetes GPG key and Repository
curl -fsSL [https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key](https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key) | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] [https://pkgs.k8s.io/core:/stable:/v1.30/deb/](https://pkgs.k8s.io/core:/stable:/v1.30/deb/) /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 3. Cloning the Cluster Nodes
Once the base image is ready, we use the WSL export/import feature to create our distinct nodes:
```powershell
# In Windows PowerShell:
# 1. Export the pre-configured base
wsl --export Ubuntu-24.04 k8s-base.tar

# 2. Import as separate Node instances
wsl --import k8scluster C:\wsl\k8scluster k8s-base.tar
wsl --import k8snode1 C:\wsl\k8snode1 k8s-base.tar
wsl --import k8snode2 C:\wsl\k8snode2 k8s-base.tar
```

---

## 🚀 Deployment Workflow

### Step 1: Initialize Control Plane (k8scluster)
Log into the `k8scluster` distribution and run the initialization. We explicitly define the Service and Pod CIDRs.
```bash
sudo kubeadm init \
  --pod-network-cidr=10.100.0.0/16 \
  --service-cidr=192.168.0.0/16 \
  --node-name k8scluster
```

### Step 2: Setup Client Access (kubeconfig)
To allow `kubectl` to communicate with the API server, export the admin configuration:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 3: Register Worker Nodes
Run the join command (provided by the `kubeadm init` output) on `k8snode1` and `k8snode2`:
```bash
sudo kubeadm join <k8scluster-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Step 4: Install Cilium CNI
Install Cilium via Helm to manage the networking datapath.
```bash
helm install cilium cilium/cilium --version 1.15.3 \
  --namespace kube-system \
  --set ipam.mode=cluster-pool \
  --set ipam.operator.clusterPoolIPv4PodCIDRList='{10.100.0.0/16}' \
  --set ipam.operator.clusterPoolIPv4MaskSize=24
```

---

## 🛠️ Debugging and Lessons Learned

* **API/Etcd Race Conditions:** During cold boots, the API Server may log `authentication handshake failed` because it starts faster than the Etcd container. This is transient and resolves automatically.
* **Network Verification:** Verified the Etcd mTLS connection using:
  `curl -v --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/apiserver-etcd-client.crt --key /etc/kubernetes/pki/apiserver-etcd-client.key https://127.0.0.1:2379/health`
* **Cgroup Compatibility:** Ensuring `SystemdCgroup = true` in the containerd configuration is mandatory for stable node registration on Ubuntu 24.04.

---
*Created for the WSL2 K8s Lab - April 2026*
```