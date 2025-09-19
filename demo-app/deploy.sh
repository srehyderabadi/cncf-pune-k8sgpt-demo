#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting build and deploy process..."

# Define variables
IMAGE_NAME="cncf-pune-demo"
IMAGE_TAG="latest"
CLUSTER_NAME="cncf-pune-k3d-demo"

# Clean up existing resources
echo "🧹 Cleaning up existing resources..."
docker stop $(docker ps -q --filter name=demo-app-container) 2>/dev/null || true
docker rm $(docker ps -aq --filter name=demo-app-container) 2>/dev/null || true
docker rmi ${IMAGE_NAME}:${IMAGE_TAG} demo-app:${IMAGE_TAG} 2>/dev/null || true

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Remove existing pods to ensure fresh image is pulled
echo "🗑️ Removing existing pods..."
kubectl delete pods -l app=cncf-pune-demo 2>/dev/null || true

# Clean and import image into K3d cluster
echo "🧹 Cleaning up existing image in k3d cluster..."
for node in $(k3d node list | grep "${CLUSTER_NAME}-server" | awk '{print $1}'); do
    echo "Removing image from node: $node"
    docker exec $node crictl rmi ${IMAGE_NAME}:${IMAGE_TAG} 2>/dev/null || true
done

echo "📤 Importing fresh image to K3d cluster..."
k3d image import ${IMAGE_NAME}:${IMAGE_TAG} -c ${CLUSTER_NAME}

# Create namespace if it doesn't exist
echo "📁 Creating namespace if it doesn't exist..."
kubectl create namespace demo 2>/dev/null || true



# Check if deployment exists before attempting restart
if kubectl get deployment cncf-pune-demo -n demo >/dev/null 2>&1; then
    echo "🔄 Rolling restart of deployment..."
    kubectl rollout restart deployment/cncf-pune-demo -n demo
else
    echo "⚠️ Deployment not found, skipping restart..."
    # Apply Kubernetes manifests
    echo "🎮 Deploying to Kubernetes..."
    kubectl apply -f k8s/deployment.yaml
fi

# Wait for deployment to roll out
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/cncf-pune-demo -n demo

# Display status
echo -e "\n📊 Deployment Status:"
echo "----------------------"
kubectl get pods -l app=cncf-pune-demo -n demo
echo -e "\n🔌 Service Status:"
echo "----------------------"
kubectl get svc cncf-pune-demo -n demo
echo -e "\n🌐 Ingress Status:"
echo "----------------------"
kubectl get ingress cncf-pune-demo -n demo

echo -e "\n✅ Deployment complete!"
echo "🌍 You can access the application at: http://cncf.vg.local"