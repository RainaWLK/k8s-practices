# Install K8s Cluster in WSL2 Environment (Windows)

This project documents the architecture and deployment steps for a multi-node Kubernetes cluster running locally on Windows using **WSL2 (Windows Subsystem for Linux)**. By using separate WSL2 distributions as nodes, we achieve a realistic multi-node environment with minimal overhead on a single host.

## 🌐 Network Architecture

The cluster is configured with specific CIDR ranges to ensure isolation and avoid routing conflicts with the Windows host and the internal WSL2 network.

| Component | CIDR Range | Description |
| :--- | :--- | :--- |
| **Node CIDR** | Dynamic (WSL2) | Assigned by the WSL2 virtual switch (e.g., 172.x.x.x) |
| **Pod CIDR** | `10.100.0.0/16` | Managed by Cilium CNI |
| **Service CIDR** | `192.168.0.0/16` | Kubernetes Service Cluster IPs |

---

## 🏗️ Cluster Architecture

### 1. Host Initialization & Base Image
* **OS:** Windows 11 with WSL2 enabled.
* **Base Distribution:** **Ubuntu 24.04**.
* **Pre-configuration:**
    * Network: `net.ipv4.ip_forward = 1` and bridge-nf-call-iptables enabled.
    * Runtime: `containerd` (CRI) installed and optimized.
    * Tools: `kubelet`, `kubeadm`, and `kubectl` installed.
    * Environment: WSL2 kernel compatibility checks for eBPF (required by Cilium).

### 2. Node Deployment (Cloning Strategy)
To ensure identical environments across the cluster, the base image was cloned into three distinct WSL2 distributions:
* `k8scluster`: Dedicated Control Plane node.
* `k8snode1`: Worker Node 01.
* `k8snode2`: Worker Node 02.

---

## 🚀 Deployment Workflow

### Step 1: Control Plane Initialization
Initialized the primary node using `kubeadm` with the defined CIDR ranges:
```bash
sudo kubeadm init --pod-network-cidr=10.100.0.0/16 --service-cidr=192.168.0.0/16