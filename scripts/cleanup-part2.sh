#!/bin/bash

echo "Cleaning up Kubernetes Gateway API POC - Part 2"
echo "================================================"

# Stop port forwarding
echo "Stopping port forwarding..."
pkill -f "port-forward.*nginx-gateway" 2>/dev/null || echo "No port forwarding process found"

# Delete Part 2 resources
echo "Removing Part 2 resources..."
kubectl delete -f manifests/part2/http-route.yaml --ignore-not-found=true
kubectl delete -f manifests/part2/gateway.yaml --ignore-not-found=true
kubectl delete -f manifests/part2/app2-deployment.yaml --ignore-not-found=true
kubectl delete -f manifests/part2/app1-deployment.yaml --ignore-not-found=true

# Wait for cleanup
echo "Waiting for resources to be cleaned up..."
sleep 5

# Verify cleanup
echo ""
echo "Verifying cleanup..."
echo "Remaining pods:"
kubectl get pods -l 'app in (app1,app2)' 2>/dev/null || echo "No app pods found (cleanup successful)"

echo "Remaining services:"
kubectl get services app1-service app2-service 2>/dev/null || echo "No app services found (cleanup successful)"

echo "Gateway and HTTPRoute:"
kubectl get gateway my-gateway 2>/dev/null || echo "Gateway removed (cleanup successful)"
kubectl get httproute my-route 2>/dev/null || echo "HTTPRoute removed (cleanup successful)"

echo ""
echo "================================================"
echo "✅ Part 2 cleanup completed!"
echo "Part 1 (Kind cluster and Gateway API) is still running"
echo "To completely clean up: kind delete cluster --name gateway-api-poc"
echo "================================================"