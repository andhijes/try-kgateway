#!/bin/bash

echo "Cleaning up Kubernetes Gateway API POC - Part 3"
echo "================================================"

# Scale back to single replica
echo "Scaling app1 back to 1 replica..."
kubectl scale deployment app1 --replicas=1

# Wait for scaling to complete
kubectl wait --for=condition=ready pod -l app=app1 --timeout=60s

# Restore original Part 2 deployment configuration
echo "Restoring original Part 2 deployment configuration..."
kubectl apply -f manifests/part2/app1-deployment.yaml

# Restore original Part 2 HTTPRoute
echo "Restoring original Part 2 routing configuration..."
kubectl apply -f manifests/part2/http-route.yaml

# Clean up advanced routes if they exist
echo "Removing advanced routing configurations..."
kubectl delete httproute my-route-weighted my-route-headers 2>/dev/null || echo "No advanced routes to remove"

# Wait for rollout
echo "Waiting for deployment rollout to complete..."
kubectl rollout status deployment/app1

# Verify cleanup
echo ""
echo "Verifying cleanup..."
echo "App1 pods (should be 1):"
kubectl get pods -l app=app1

echo ""
echo "Service endpoints (should be 1):"
kubectl get endpoints app1-service --no-headers | awk '{print $2}' | tr ',' '\n' | wc -l | xargs echo "Total endpoints:"

echo ""
echo "Active HTTPRoutes:"
kubectl get httproute

# Test that basic routing still works
echo ""
echo "Testing basic routing functionality..."
echo "Testing root path (should work):"
curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "Test failed"

echo "Testing admin path (should work):"
curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "Test failed"

echo ""
echo "================================================"
echo "✅ Part 3 cleanup completed!"
echo "Reverted to Part 2 configuration:"
echo "- App1: 1 replica"
echo "- Original Part 2 routing rules restored"
echo "- Advanced routing configurations removed"
echo ""
echo "Part 2 functionality is still available:"
echo "  curl -H \"Host: app1.local\" http://localhost:8080/"
echo "  curl -H \"Host: app1.local\" http://localhost:8080/admin"
echo ""
echo "To completely clean up: ./scripts/cleanup-part2.sh"
echo "To restart Part 3: ./scripts/start-part3.sh"
echo "================================================"