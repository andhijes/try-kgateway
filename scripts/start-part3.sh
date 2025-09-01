#!/bin/bash

echo "Starting Kubernetes Gateway API POC - Part 3: Load Balancing & Advanced Routing"
echo "================================================================================"

# Check if Part 2 is running
echo "Checking Part 2 prerequisites..."
if ! kubectl get httproute my-route >/dev/null 2>&1; then
    echo "❌ Error: Part 2 not completed. Please run Part 2 first."
    echo "Run: ./scripts/start-part2.sh"
    exit 1
fi

echo "✅ Part 2 prerequisites satisfied"

# Check if already scaled
current_replicas=$(kubectl get deployment app1 -o jsonpath='{.spec.replicas}')
echo "Current app1 replicas: $current_replicas"

if [ "$current_replicas" -lt 3 ]; then
    echo "Scaling app1 to 3 replicas for load balancing..."
    kubectl scale deployment app1 --replicas=3
    
    echo "Waiting for all replicas to be ready..."
    kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s
else
    echo "✅ App1 already scaled to $current_replicas replicas"
fi

# Apply enhanced deployment with better pod visibility
echo ""
echo "Applying enhanced deployment configuration..."
kubectl apply -f manifests/part3/app1-enhanced.yaml

# Wait for rollout to complete
echo "Waiting for deployment rollout to complete..."
kubectl rollout status deployment/app1

# Verify scaling
echo ""
echo "Verifying load balancing setup..."
echo "App1 pods:"
kubectl get pods -l app=app1

echo ""
echo "Service endpoints:"
kubectl get endpoints app1-service

# Test basic load balancing
echo ""
echo "Testing basic load balancing..."
./scripts/test-load-balancing.sh

echo ""
echo "Running comprehensive tests..."
./scripts/test-advanced-routing.sh

echo ""
echo "================================================================================"
echo "✅ Part 3 basic setup completed successfully!"
echo ""
echo "Available advanced routing tests:"
echo "  ./scripts/test-weighted-routing.sh    # Test canary deployments (70/30 split)"
echo "  ./scripts/test-header-routing.sh      # Test premium user routing"
echo "  ./scripts/test-advanced-routing.sh    # Full comprehensive tests"
echo ""
echo "Scaling options:"
echo "  kubectl scale deployment app1 --replicas=5    # Scale to more replicas"
echo "  kubectl scale deployment app1 --replicas=1    # Scale back down"
echo ""
echo "Port forwarding is still active (PID: $(pgrep -f 'port-forward.*nginx-gateway' || echo 'not found'))"
echo "================================================================================"