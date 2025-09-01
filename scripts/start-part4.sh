#!/bin/bash

echo "🚀 Starting Kubernetes Gateway API POC - Part 4: gRPC Routing"
echo "=============================================================="

# Check if Kind cluster exists
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Kubernetes cluster not accessible. Please run Part 1 first."
    exit 1
fi

# Check if Gateway API and NGINX Gateway Fabric are installed
if ! kubectl get gatewayclass nginx >/dev/null 2>&1; then
    echo "❌ NGINX Gateway Fabric not found. Please run Part 1 first."
    exit 1
fi

echo "✅ Prerequisites verified"
echo ""

# Step 1: Deploy gRPC services
echo "📦 Step 1: Deploying gRPC Services"
echo "Deploying gRPC health service..."
kubectl apply -f manifests/part4/grpc-health-service.yaml

echo "Deploying gRPC greeter service..."
kubectl apply -f manifests/part4/grpc-greeter-service.yaml

echo "Waiting for gRPC service pods to be ready..."
kubectl wait --for=condition=ready pod -l app=grpc-health --timeout=60s --all
kubectl wait --for=condition=ready pod -l app=grpc-greeter --timeout=60s

echo "✅ gRPC services deployed successfully"
echo ""

# Step 2: Configure Gateway for gRPC
echo "🌐 Step 2: Configuring Gateway with gRPC Listener"
kubectl apply -f manifests/part4/gateway-grpc.yaml

echo "Waiting for gateway to be ready..."
sleep 5

echo "✅ Gateway configured with HTTP/2 listener"
echo ""

# Step 3: Deploy gRPC routing
echo "🔄 Step 3: Deploying gRPC Route Configuration"
echo "Applying GRPCRoute..."
kubectl apply -f manifests/part4/grpc-route.yaml

echo "Applying HTTPRoute fallback..."
kubectl apply -f manifests/part4/grpc-http-route.yaml

echo "Waiting for routes to be accepted..."
sleep 5

echo "✅ gRPC routing configured"
echo ""

# Step 4: Deploy test client
echo "🧪 Step 4: Deploying gRPC Test Client"
kubectl apply -f manifests/part4/grpc-client.yaml
kubectl wait --for=condition=ready pod grpc-client --timeout=60s

echo "✅ Test client deployed"
echo ""

# Step 5: Verify deployment
echo "🔍 Step 5: Verifying Deployment"
echo ""
echo "Gateway status:"
kubectl get gateway my-gateway
echo ""

echo "gRPC services:"
kubectl get pods,services -l 'app in (grpc-health,grpc-greeter)'
echo ""

echo "Routes:"
kubectl get grpcroute,httproute | grep grpc
echo ""

# Step 6: Run tests
echo "🚀 Step 6: Running gRPC Routing Tests"
echo ""
./scripts/test-grpc-routing.sh

echo ""
echo "=============================================================="
echo "🎉 Part 4: gRPC Routing Setup Complete!"
echo ""
echo "✅ What's been deployed:"
echo "   • gRPC Health Service (2 replicas)"
echo "   • gRPC Greeter Service (1 replica)"
echo "   • Gateway with HTTP/2 listener on port 8080"
echo "   • GRPCRoute for native gRPC routing"
echo "   • HTTPRoute fallback for compatibility"
echo "   • Test client pod with networking tools"
echo ""
echo "📋 Next steps:"
echo "   • Run: ./scripts/test-grpc-load-balancing.sh"
echo "   • Install grpcurl for full gRPC testing"
echo "   • Monitor service performance and scaling"
echo ""
echo "🧹 To cleanup: ./scripts/cleanup-part4.sh"