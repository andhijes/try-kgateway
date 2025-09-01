#!/bin/bash

echo "Testing Header-Based Routing"
echo "============================="

# Apply header-based routing configuration
echo "Applying header-based routing configuration..."
kubectl apply -f manifests/part3/header-based-route.yaml

# Wait for changes to take effect
sleep 3

echo ""
echo "Test 1: Premium user routing (with X-User-Type: premium header)"
echo "Expected: /api requests should go to app2 (admin backend)"

for i in {1..5}; do
    echo -n "Premium API request $i: "
    response=$(curl -s -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/api)
    hostname=$(echo "$response" | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "unknown")
    header_received=$(echo "$response" | jq -r '.http.headers."x-user-type" // "not-received"' 2>/dev/null || echo "unknown")
    
    if [[ "$hostname" == app2-* ]]; then
        echo "✅ Routed to app2 ($hostname) - header: $header_received"
    else
        echo "❌ Routed to wrong service ($hostname) - header: $header_received" 
    fi
    sleep 0.3
done

echo ""
echo "Test 2: Regular user routing (without premium header)"
echo "Expected: /api requests should go to app1 (main backend)"

for i in {1..5}; do
    echo -n "Regular API request $i: "
    response=$(curl -s -H "Host: app1.local" http://localhost:8080/api)
    hostname=$(echo "$response" | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "unknown")
    
    if [[ "$hostname" == app1-* ]]; then
        echo "✅ Routed to app1 ($hostname)"
    else
        echo "❌ Routed to wrong service ($hostname)"
    fi
    sleep 0.3
done

echo ""
echo "Test 3: Different header value"
echo "Expected: Should route to regular backend (app1)"

for i in {1..3}; do
    echo -n "API request with different header $i: "
    response=$(curl -s -H "Host: app1.local" -H "X-User-Type: standard" http://localhost:8080/api)
    hostname=$(echo "$response" | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "unknown")
    header_received=$(echo "$response" | jq -r '.http.headers."x-user-type" // "not-received"' 2>/dev/null || echo "unknown")
    
    if [[ "$hostname" == app1-* ]]; then
        echo "✅ Routed to app1 ($hostname) - header: $header_received"
    else
        echo "❌ Routed to wrong service ($hostname) - header: $header_received"
    fi
    sleep 0.3
done

echo ""
echo "Test 4: Admin path should still work (bypass header rules)"
echo "Expected: Always route to app2 regardless of headers"

for i in {1..3}; do
    echo -n "Admin request $i: "
    response=$(curl -s -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/admin)
    hostname=$(echo "$response" | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "unknown")
    
    if [[ "$hostname" == app2-* ]]; then
        echo "✅ Routed to app2 ($hostname)"
    else
        echo "❌ Routed to wrong service ($hostname)"
    fi
    sleep 0.3
done

echo ""
echo "Test 5: Root path should load balance across app1 pods"
temp_root=$(mktemp)

for i in {1..8}; do
    curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null >> "$temp_root"
    sleep 0.2
done

echo "Root path load balancing:"
sort "$temp_root" | uniq -c

unique_pods=$(sort "$temp_root" | uniq | grep "app1-" | wc -l)
echo "Unique app1 pods responding: $unique_pods"

rm -f "$temp_root"

echo ""
echo "============================="
echo "Header-based routing test completed!"
echo ""
echo "Summary:"
echo "- Premium users (X-User-Type: premium) → app2 for /api paths"
echo "- Regular users → app1 for /api paths" 
echo "- Admin paths → always app2"
echo "- Root path → load balanced across app1 pods"
echo ""
echo "To restore original routing:"
echo "  kubectl apply -f manifests/part2/http-route.yaml"