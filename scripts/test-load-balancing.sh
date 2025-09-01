#!/bin/bash

echo "Testing Load Balancing Across Multiple Pods"
echo "==========================================="

echo "Making 15 requests to see load distribution..."
for i in {1..15}; do
    echo -n "Request $i: "
    curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null || echo "Failed"
    sleep 0.3
done

echo ""
echo "==========================================="
echo "Load balancing test completed!"
echo "Different pod names indicate successful load balancing."
echo ""

# Show current pod status
echo "Current app1 pods:"
kubectl get pods -l app=app1 --no-headers | awk '{print $1 " - " $3}'

echo ""
echo "Service endpoints:"
kubectl get endpoints app1-service --no-headers | awk '{print $2}' | tr ',' '\n' | wc -l | xargs echo "Total endpoints:"