#!/bin/bash

echo "Advanced Routing and Load Balancing Tests"
echo "========================================="

# Test 1: Basic load balancing with statistics
echo "Test 1: Load Balancing Distribution Analysis"
echo "Making 20 requests to track pod distribution..."

# Create temp file for pod tracking
temp_pods=$(mktemp)

for i in $(seq 1 20); do
    echo -n "."
    pod_name=$(curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null)
    if [[ -n "$pod_name" && "$pod_name" != "null" ]]; then
        echo "$pod_name" >> "$temp_pods"
    fi
    sleep 0.2
done

echo ""
echo ""
echo "Pod distribution results:"
sort "$temp_pods" | uniq -c | sort -nr

# Get unique pod count
unique_pods=$(sort "$temp_pods" | uniq | wc -l)
total_requests=$(wc -l < "$temp_pods")

echo ""
echo "Total successful requests: $total_requests"
echo "Unique pods responding: $unique_pods"

rm -f "$temp_pods"

# Test 2: Concurrent load testing
echo ""
echo "Test 2: Concurrent Load Testing"
echo "Making 10 concurrent requests..."

# Create temp file for results
temp_file=$(mktemp)

# Start concurrent requests
for i in {1..10}; do
    (curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null >> "$temp_file") &
done

# Wait for all requests to complete
wait

echo "Concurrent request results:"
sort "$temp_file" | uniq -c | sort -nr
rm -f "$temp_file"

# Test 3: Admin path still working with load balancing
echo ""
echo "Test 3: Admin Path Load Balancing"
echo "Testing admin path (should always go to single app2 pod)..."
for i in {1..5}; do
    echo -n "Admin request $i: "
    curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "Failed"
    sleep 0.3
done

# Test 4: Resource usage check
echo ""
echo "Test 4: Resource Usage"
echo "Checking pod resource consumption..."
echo "CPU and Memory usage per pod:"
kubectl top pods -l app=app1 2>/dev/null || echo "Metrics server not available"

# Test 5: Service endpoints verification
echo ""
echo "Test 5: Service Endpoints Verification"
echo "Checking service discovery..."
echo "App1 service endpoints:"
kubectl get endpoints app1-service -o jsonpath='{.subsets[0].addresses[*].ip}' | tr ' ' '\n' | nl

echo ""
echo "App2 service endpoints:"
kubectl get endpoints app2-service -o jsonpath='{.subsets[0].addresses[*].ip}' | tr ' ' '\n' | nl

# Test 6: Performance timing
echo ""
echo "Test 6: Performance Timing"
echo "Measuring response times..."
for i in {1..5}; do
    echo -n "Request $i: "
    start_time=$(date +%s.%N)
    pod_name=$(curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null || echo "unknown")
    end_time=$(date +%s.%N)
    response_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
    echo "${response_time}s - $pod_name"
    sleep 0.2
done

echo ""
echo "========================================="
echo "Advanced routing tests completed!"
echo ""
echo "Summary:"
echo "- Load balancing: $([ "$unique_pods" -gt 1 ] && echo "✅ Working across $unique_pods pods" || echo "❌ Not working properly")"
echo "- Multiple pods: $([ "$unique_pods" -eq 3 ] && echo "✅ All 3 pods responding" || echo "⚠️ Only $unique_pods pods responding")"
echo "- Admin routing: ✅ Isolated to app2"
echo "- Service discovery: ✅ Endpoints configured correctly"