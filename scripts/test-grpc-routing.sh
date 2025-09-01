#!/bin/bash

echo "Testing gRPC Service Routing via Gateway API"
echo "============================================="

# Check prerequisites
echo "Checking prerequisites..."
if ! kubectl get pod grpc-client >/dev/null 2>&1; then
    echo "❌ gRPC client pod not found. Deploying..."
    kubectl apply -f manifests/part4/grpc-client.yaml
    kubectl wait --for=condition=ready pod grpc-client --timeout=60s
fi

if ! kubectl get grpcroute grpc-route >/dev/null 2>&1; then
    echo "❌ GRPCRoute not found. Please deploy Part 4 first."
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# Test 1: Direct service connectivity
echo "Test 1: Direct Service Connectivity"
echo "Testing direct connection to health service..."
if kubectl exec grpc-client -- nc -zv grpc-health-service 50051 >/dev/null 2>&1; then
    echo "✅ Health service direct connectivity: PASSED"
else
    echo "❌ Health service direct connectivity: FAILED"
fi

echo "Testing direct connection to greeter service..."
if kubectl exec grpc-client -- nc -zv grpc-greeter-service 50051 >/dev/null 2>&1; then
    echo "✅ Greeter service direct connectivity: PASSED"
else
    echo "❌ Greeter service direct connectivity: FAILED"
fi

echo ""

# Test 2: Gateway configuration status
echo "Test 2: Gateway and Route Configuration"
echo "Checking Gateway status..."
GATEWAY_STATUS=$(kubectl get gateway my-gateway -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')
if [ "$GATEWAY_STATUS" = "True" ]; then
    echo "✅ Gateway programmed: PASSED"
else
    echo "❌ Gateway programmed: FAILED - Status: $GATEWAY_STATUS"
fi

echo "Checking GRPCRoute status..."
GRPCROUTE_STATUS=$(kubectl get grpcroute grpc-route -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
if [ "$GRPCROUTE_STATUS" = "True" ]; then
    echo "✅ GRPCRoute accepted: PASSED"
else
    echo "❌ GRPCRoute accepted: FAILED - Status: $GRPCROUTE_STATUS"
fi

echo ""

# Test 3: Service endpoints
echo "Test 3: Service Endpoints Verification"
echo "Health service endpoints:"
kubectl get endpoints grpc-health-service
echo ""
echo "Greeter service endpoints:"
kubectl get endpoints grpc-greeter-service
echo ""

# Test 4: Load balancing verification
echo "Test 4: Load Balancing Verification"
echo "Scaling health service to 3 replicas..."
kubectl scale deployment grpc-health --replicas=3
kubectl wait --for=condition=ready pod -l app=grpc-health --timeout=60s --all

echo "Health service pods:"
kubectl get pods -l app=grpc-health -o wide
echo ""

echo "Service endpoints after scaling:"
kubectl get endpoints grpc-health-service
echo ""

# Test 5: Basic HTTP connectivity test (since actual gRPC requires grpcurl)
echo "Test 5: Gateway HTTP Connectivity Test"
echo "Testing HTTP connectivity to gateway service..."
GATEWAY_SERVICE_IP=$(kubectl get service nginx-gateway -n nginx-gateway -o jsonpath='{.spec.clusterIP}')
if kubectl exec grpc-client -- nc -zv $GATEWAY_SERVICE_IP 80 >/dev/null 2>&1; then
    echo "✅ Gateway HTTP connectivity: PASSED"
else
    echo "❌ Gateway HTTP connectivity: FAILED"
fi

echo ""
echo "============================================="
echo "gRPC routing tests completed!"
echo ""
echo "Note: For full gRPC protocol testing, install grpcurl in the client pod:"
echo "kubectl exec grpc-client -- apk add --no-cache wget"
echo "kubectl exec grpc-client -- wget -O /usr/local/bin/grpcurl https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz"
echo ""
echo "Current configuration uses native GRPCRoute with fallback HTTPRoute."
echo "Services are running mock gRPC servers on port 50051."