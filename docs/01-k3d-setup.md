# 🐳 K3D Setup Guide

This guide covers setting up K3D (K3s in Docker) for the CNCF Pune demo environment.

## Overview

K3D creates lightweight Kubernetes clusters using Docker containers. It's perfect for local development and demos because it's fast, lightweight, and requires minimal resources.

## Prerequisites

- **macOS**: This guide is tested on macOS Monterey and newer
- **Homebrew**: Package manager for macOS (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`)
- **Docker Desktop**: Required for running containers (`brew install --cask docker`)
- **4GB+ RAM**: Recommended for smooth operation
- **2GB+ disk space**: For cluster and container images

## Automatic Installation

Use the provided script for automated setup:

```bash
./scripts/install-k3d.sh
```

This script will:
- ✅ Check all prerequisites
- 🔧 Install kubectl and K3D via Homebrew
- 🚀 Create the demo cluster
- 🧪 Validate cluster functionality
- 🎨 Install kubecolor for better output

## Manual Installation Steps

If you prefer manual installation:

### 1. Install Tools

```bash
# Install kubectl
brew install kubectl

# Install k3d
brew install k3d

# Install kubecolor (optional but recommended)
brew install kubecolor
```

### 2. Create Cluster Configuration

```yaml
# k3d_cluster/k3d-cluster.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: cncf-pune-k3d-demo
servers: 1
agents: 0
kubeAPI:
  host: "0.0.0.0"
  hostIP: "127.0.0.1"
  hostPort: "6443"
ports:
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
```

### 3. Create Cluster

```bash
# Create cluster using config
k3d cluster create --config k3d_cluster/k3d-cluster.yaml

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### 4. Create Demo Namespace

```bash
kubectl create namespace demo
```

## Cluster Configuration Details

### Cluster Specifications
- **Name**: `cncf-pune-k3d-demo`
- **Servers**: 1 (control plane)
- **Agents**: 0 (worker nodes - using server for simplicity)
- **API Server**: `https://127.0.0.1:6443`

### Port Mappings
- **80**: HTTP traffic (for demo app)
- **443**: HTTPS traffic
- **8080**: Alternative HTTP port
- **6443**: Kubernetes API server

### Disabled Components
- **Traefik**: Disabled to avoid conflicts and simplify setup

## Validation Commands

```bash
# Check cluster status
kubectl cluster-info

# List nodes
kubectl get nodes -o wide

# Check all pods across namespaces
kubectl get pods --all-namespaces

# Verify demo namespace
kubectl get namespaces | grep demo

# Test basic functionality
kubectl run test-pod --image=nginx:alpine -n demo --rm -it -- /bin/sh
```

## Troubleshooting

### Common Issues

#### 1. Docker Not Running
```bash
Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```
**Solution**: Start Docker Desktop application

#### 2. Port Already in Use
```bash
Error: port 6443 already allocated
```
**Solutions**:
- Change port in config file
- Stop conflicting processes: `sudo lsof -i :6443`
- Delete existing cluster: `k3d cluster delete cncf-pune-k3d-demo`

#### 3. Insufficient Resources
```bash
Error: failed to create cluster
```
**Solutions**:
- Increase Docker Desktop memory to 4GB+
- Increase Docker Desktop disk space to 10GB+
- Close other resource-heavy applications

#### 4. Context Not Set
```bash
Error: The connection to the server localhost:8080 was refused
```
**Solution**:
```bash
kubectl config use-context k3d-cncf-pune-k3d-demo
```

### Advanced Troubleshooting

#### Check Docker Resources
```bash
docker system df  # Check disk usage
docker stats      # Check resource usage
```

#### K3D Cluster Management
```bash
# List all clusters
k3d cluster list

# Get cluster info
k3d cluster get cncf-pune-k3d-demo

# Stop cluster (preserves data)
k3d cluster stop cncf-pune-k3d-demo

# Start stopped cluster
k3d cluster start cncf-pune-k3d-demo

# Delete cluster completely
k3d cluster delete cncf-pune-k3d-demo
```

#### Kubeconfig Management
```bash
# Export kubeconfig
k3d kubeconfig get cncf-pune-k3d-demo

# Merge kubeconfig with existing
k3d kubeconfig merge cncf-pune-k3d-demo --kubeconfig-switch-context

# List available contexts
kubectl config get-contexts
```

## Performance Optimization

### Docker Desktop Settings
- **Memory**: 4GB minimum, 8GB recommended
- **CPUs**: 2 minimum, 4 recommended
- **Disk**: 20GB+ available space

### K3D Optimizations
```bash
# Create cluster with resource limits
k3d cluster create demo-optimized \
  --agents 0 \
  --servers 1 \
  --k3s-arg '--kubelet-arg=max-pods=50@server:0' \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer
```

## Next Steps

Once K3D is set up:

1. **Install Ollama**: Run `./scripts/install-ollama.sh`
2. **Install K8sGPT**: Run `./scripts/install-k8sgpt.sh`
3. **Deploy Demo App**: Run `./scripts/setup-demo.sh`
4. **Validate Setup**: Run `./scripts/validate-setup.sh`

## Useful Commands Reference

```bash
# Quick cluster status check
kubectl get nodes,pods,svc,ns

# Port forward for external access
kubectl port-forward svc/service-name 8080:80 -n namespace

# Execute commands in cluster
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Monitor resources
kubectl top nodes
kubectl top pods --all-namespaces
```

## Security Considerations

For demo purposes, this setup uses:
- Simplified RBAC (suitable for demos)
- No network policies
- Default service accounts

For production use, consider:
- Implementing proper RBAC
- Network segmentation
- Pod security policies
- Resource quotas

## Resources

- [K3D Documentation](https://k3d.io/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Documentation](https://docs.docker.com/desktop/)