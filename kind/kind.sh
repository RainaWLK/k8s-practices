#!/bin/bash

hostnamectl set-hostname k8scluster

# Download the latest version for AMD64
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
# Make it executable
chmod +x ./kind
# Move it to your path
sudo mv ./kind /usr/local/bin/kind