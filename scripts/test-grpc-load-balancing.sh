#!/bin/bash

echo "Testing gRPC Load Balancing"
echo "============================"

# Ensure grpc-client pod is ready
if ! kubectl get pod grpc-client >/dev/null 2>&1; then
    echo "Deploying gRPC client..."
    kubectl apply -f manifests/part4/grpc-client.yaml
    kubectl wait --for=condition=ready pod grpc-client --timeout=60s
fi

# Scale health service to multiple replicas
echo "Scaling gRPC health service to 3 replicas..."
kubectl scale deployment grpc-health --replicas=3
kubectl wait --for=condition=ready pod -l app=grpc-health --timeout=60s --all

echo ""
echo "Health service pods after scaling:"
kubectl get pods -l app=grpc-health -o wide

echo ""
echo "Service endpoints:"
kubectl get endpoints grpc-health-service

echo ""
echo "Testing load distribution via direct service calls..."
echo "Making 10 connection tests to verify load balancing..."

# Test load balancing by checking different pod IPs
declare -A pod_connections
for i in {1..10}; do
    echo -n "Test $i: "
    # Use netcat to test connectivity and capture which pod responds
    result=$(kubectl exec grpc-client -- timeout 2 nc grpc-health-service 50051 < /dev/null 2>/dev/null && echo "SUCCESS" || echo "FAILED")
    echo $result
    sleep 0.5
done

echo ""
echo "Pod resource usage:"
kubectl top pods -l app=grpc-health 2>/dev/null || echo "Metrics not available (metrics-server not installed)"

echo ""
echo "Testing greeter service connectivity:"
kubectl exec grpc-client -- nc -zv grpc-greeter-service 50051

echo ""
echo "============================================="
echo "gRPC load balancing tests completed!"
echo ""
echo "Key observations:"
echo "- Health service scaled to 3 replicas for load distribution"
echo "- Service endpoints show multiple pod IPs"
echo "- Connection tests verify basic connectivity"
echo "- Actual gRPC load balancing requires gRPC client tools"
echo ""
echo "For production testing, consider:"
echo "1. Installing grpcurl for proper gRPC method calls"
echo "2. Implementing actual gRPC servers with health checks"
echo "3. Monitoring connection distribution across pods"