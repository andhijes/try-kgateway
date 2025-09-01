#!/bin/bash

echo "Starting Kubernetes Gateway API POC - Part 2: Basic HTTP Routing"
echo "================================================================="

# Check if Part 1 is running
echo "Checking Part 1 prerequisites..."
if ! kubectl get gatewayclass nginx >/dev/null 2>&1; then
    echo "❌ Error: Part 1 not completed. Please run Part 1 first."
    echo "Run: kind create cluster --config manifests/part1/kind-config.yaml"
    echo "Then install Gateway API and NGINX Gateway Fabric"
    exit 1
fi

echo "✅ Part 1 prerequisites satisfied"

# Deploy Part 2 applications
echo ""
echo "Deploying demo applications..."
kubectl apply -f manifests/part2/app1-deployment.yaml
kubectl apply -f manifests/part2/app2-deployment.yaml

echo "Creating Gateway and HTTPRoute resources..."
kubectl apply -f manifests/part2/gateway.yaml
kubectl apply -f manifests/part2/http-route.yaml

# Wait for pods to be ready
echo ""
echo "Waiting for applications to be ready..."
kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s
kubectl wait --for=condition=ready pod -l app=app2 --timeout=120s

# Check status
echo ""
echo "Verifying deployment status..."
echo "Applications:"
kubectl get pods -l 'app in (app1,app2)'

echo ""
echo "Services:"
kubectl get services app1-service app2-service

echo ""
echo "Gateway and Route:"
kubectl get gateway my-gateway
kubectl get httproute my-route

# Start port forwarding
echo ""
echo "Starting port forwarding (running in background)..."
pkill -f "port-forward.*nginx-gateway" 2>/dev/null || true
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &
sleep 3

# Test connectivity
echo ""
echo "Testing routing functionality..."
./scripts/test-routing.sh

echo ""
echo "================================================================="
echo "✅ Part 2 deployment completed successfully!"
echo ""
echo "You can now test the routes manually:"
echo "  curl -H \"Host: app1.local\" http://localhost:8080/"
echo "  curl -H \"Host: app1.local\" http://localhost:8080/admin"
echo ""
echo "Port forwarding is running in background (PID: $(pgrep -f 'port-forward.*nginx-gateway' || echo 'not found'))"
echo "To stop: pkill -f 'port-forward.*nginx-gateway'"
echo "================================================================="