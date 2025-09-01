#!/bin/bash

echo "🧹 Cleaning up Kubernetes Gateway API POC - Part 4: gRPC Routing"
echo "================================================================="

# Remove gRPC routes
echo "Removing gRPC routes..."
kubectl delete grpcroute grpc-route --ignore-not-found=true
kubectl delete httproute grpc-http-route --ignore-not-found=true

# Remove gRPC services and deployments
echo "Removing gRPC services..."
kubectl delete -f manifests/part4/grpc-health-service.yaml --ignore-not-found=true
kubectl delete -f manifests/part4/grpc-greeter-service.yaml --ignore-not-found=true

# Remove test client
echo "Removing test client..."
kubectl delete pod grpc-client --ignore-not-found=true

# Revert gateway to Part 3 configuration (remove gRPC listener)
echo "Reverting gateway configuration..."
if [ -f "manifests/part3/gateway.yaml" ]; then
    kubectl apply -f manifests/part3/gateway.yaml
elif [ -f "manifests/part2/gateway.yaml" ]; then
    kubectl apply -f manifests/part2/gateway.yaml
else
    echo "⚠️  No previous gateway configuration found. Gateway may need manual cleanup."
fi

# Wait for cleanup to complete
echo "Waiting for resources to be cleaned up..."
sleep 10

# Verify cleanup
echo ""
echo "🔍 Verifying cleanup..."
echo ""

echo "Remaining pods:"
kubectl get pods -l 'app in (grpc-health,grpc-greeter,grpc-client)' --no-headers 2>/dev/null || echo "No gRPC-related pods found ✅"

echo ""
echo "Remaining services:"
kubectl get services -l 'app in (grpc-health,grpc-greeter)' --no-headers 2>/dev/null || echo "No gRPC-related services found ✅"

echo ""
echo "Gateway status:"
kubectl get gateway my-gateway

echo ""
echo "Routes:"
kubectl get grpcroute,httproute | grep grpc || echo "No gRPC routes found ✅"

echo ""
echo "================================================================="
echo "✅ Part 4 cleanup completed!"
echo ""
echo "The environment has been reverted to the previous state."
echo "Gateway API and NGINX Gateway Fabric remain installed."
echo ""
echo "To continue with other parts:"
echo "  • Part 2: ./scripts/start-part2.sh"
echo "  • Part 3: ./scripts/start-part3.sh"
echo ""
echo "To complete cleanup: kind delete cluster --name gateway-api-poc"