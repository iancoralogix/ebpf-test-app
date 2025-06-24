#!/bin/bash

# eBPF Test App Cleanup Script
set -e

# Configuration
NAMESPACE="${NAMESPACE:-default}"

echo "Cleaning up eBPF Test App from Kubernetes..."
echo "Namespace: $NAMESPACE"

# Function to check if resource exists
resource_exists() {
    kubectl get "$1" "$2" -n "$NAMESPACE" &>/dev/null
}

# Delete deployments
echo "Deleting deployments..."
for deployment in frontend-3bp checkout-3bp payment-3bp; do
    if resource_exists deployment "$deployment"; then
        echo "  Deleting deployment: $deployment"
        kubectl delete deployment "$deployment" -n "$NAMESPACE"
    else
        echo "  Deployment $deployment not found, skipping..."
    fi
done

# Delete services
echo "Deleting services..."
for service in frontend-3bp checkout-3bp payment-3bp; do
    if resource_exists service "$service"; then
        echo "  Deleting service: $service"
        kubectl delete service "$service" -n "$NAMESPACE"
    else
        echo "  Service $service not found, skipping..."
    fi
done

# Wait for pods to be terminated
echo "Waiting for pods to be terminated..."
for app in frontend-3bp checkout-3bp payment-3bp; do
    echo "  Waiting for $app pods to terminate..."
    kubectl wait --for=delete pods -l app="$app" -n "$NAMESPACE" --timeout=120s 2>/dev/null || echo "    No $app pods found or timeout reached"
done

# Check for any remaining resources
echo ""
echo "Checking for any remaining eBPF test app resources..."
remaining_pods=$(kubectl get pods -n "$NAMESPACE" -l 'app in (frontend-3bp,checkout-3bp,payment-3bp)' --no-headers 2>/dev/null | wc -l)
remaining_services=$(kubectl get services -n "$NAMESPACE" -l 'app in (frontend-3bp,checkout-3bp,payment-3bp)' --no-headers 2>/dev/null | wc -l)
remaining_deployments=$(kubectl get deployments -n "$NAMESPACE" -l 'app in (frontend-3bp,checkout-3bp,payment-3bp)' --no-headers 2>/dev/null | wc -l)

if [ "$remaining_pods" -eq 0 ] && [ "$remaining_services" -eq 0 ] && [ "$remaining_deployments" -eq 0 ]; then
    echo "✅ All eBPF test app resources have been successfully removed!"
else
    echo "⚠️  Some resources may still be present:"
    echo "   Pods: $remaining_pods"
    echo "   Services: $remaining_services"
    echo "   Deployments: $remaining_deployments"
    echo ""
    echo "You can check manually with:"
    echo "   kubectl get all -n $NAMESPACE -l 'app in (frontend-3bp,checkout-3bp,payment-3bp)'"
fi

# Option to delete namespace if it's not default and empty
if [ "$NAMESPACE" != "default" ]; then
    echo ""
    read -p "Do you want to delete the namespace '$NAMESPACE' if it's empty? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if namespace has any resources left
        resource_count=$(kubectl get all -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$resource_count" -eq 0 ]; then
            echo "Deleting empty namespace: $NAMESPACE"
            kubectl delete namespace "$NAMESPACE"
            echo "✅ Namespace $NAMESPACE deleted successfully!"
        else
            echo "⚠️  Namespace $NAMESPACE is not empty, skipping deletion"
            echo "   Resources remaining: $resource_count"
        fi
    else
        echo "Keeping namespace: $NAMESPACE"
    fi
fi

echo ""
echo "Cleanup completed!"
echo ""
echo "To verify cleanup, run:"
echo "  kubectl get all -n $NAMESPACE -l 'app in (frontend-3bp,checkout-3bp,payment-3bp)'" 