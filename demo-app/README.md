# CNCF Pune Demo Application

This is a simple nginx-based web application that displays a welcome message for CNCF Pune, along with a Pune heritage image.

## Prerequisites

- Docker installed
- K3d cluster running
- kubectl configured to use the K3d cluster

## Quick Start

The easiest way to build and deploy the application is using the provided deploy script:

```bash
cd dempo_app
./deploy.sh
```

This script will handle building the Docker image, importing it to K3d, and deploying to Kubernetes.

## Manual Setup Instructions

1. Build the Docker image:
```bash
cd dempo_app
docker build -t cncf-pune-demo:latest .
```

2. Import the image into K3d cluster:
```bash
k3d image import cncf-pune-demo:latest
```

3. Deploy to Kubernetes:
```bash
kubectl apply -f k8s/deployment.yaml
```

4. Add host entry:
Add the following entry to your `/etc/hosts` file:
```
127.0.0.1 cncf.vg.local
```

## Accessing the Application

Once deployed, you can access the application by opening your browser and navigating to:
```
http://cncf.vg.local
```

You should see:
- A colorful welcome message: "Welcome to CNCF Pune -- Conversations"
- The date: "Sep 20 2026"
- An image of Shaniwar Wada, a historic Pune heritage site

## Deployment Status

To check the deployment status:
```bash
kubectl get pods -l app=cncf-pune-demo
kubectl get svc cncf-pune-demo
kubectl get ingress cncf-pune-demo
```