#!/bin/bash

# eBPF Test App Deployment Script
set -e

# Configuration
NAMESPACE="${NAMESPACE:-default}"
ECR_REPO="${ECR_REPO:-public.ecr.aws/w3s4j9x9/ianbowers/ebpf-test-app}"
TAG="${TAG:-latest}"

echo "Deploying eBPF Test App to Kubernetes..."
echo "Namespace: $NAMESPACE"
echo "Image: $ECR_REPO:$TAG"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Update image in Kubernetes manifests
echo "Updating image references in manifests..."
sed -i.bak "s|public\.ecr\.aws/w3s4j9x9/ianbowers/ebpf-test-app:latest|$ECR_REPO:$TAG|g" k8s/*.yaml

# Deploy services
echo "Deploying services..."
kubectl apply -f k8s/frontend-service.yaml -n $NAMESPACE
kubectl apply -f k8s/checkout-service.yaml -n $NAMESPACE
kubectl apply -f k8s/payment-service.yaml -n $NAMESPACE

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/checkout -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/payment -n $NAMESPACE

echo "Deployment completed successfully!"

# Show status
echo "Service status:"
kubectl get pods -n $NAMESPACE -l 'app in (frontend,checkout,payment)'
kubectl get services -n $NAMESPACE -l 'app in (frontend,checkout,payment)'

echo ""
echo "Test the application:"
echo "1. Port-forward to frontend service:"
echo "   kubectl port-forward -n $NAMESPACE svc/frontend 8080:8080"
echo ""
echo "2. Test endpoints:"
echo "   curl http://localhost:8080/api/health"
echo "   curl http://localhost:8080/api/info"
echo "   curl http://localhost:8080/api/simulate/purchase"
echo ""
echo "3. Generate load:"
echo "   for i in {1..100}; do curl -X GET http://localhost:8080/api/simulate/purchase; sleep 1; done" 