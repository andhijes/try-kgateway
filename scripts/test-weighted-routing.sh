#!/bin/bash

echo "Testing Weighted Routing (Canary Deployment Simulation)"
echo "========================================================"

# Apply weighted routing configuration
echo "Applying weighted routing configuration..."
kubectl apply -f manifests/part3/weighted-route.yaml

# Wait a moment for changes to take effect
sleep 3

echo "Testing /canary path with 70/30 weight distribution..."
echo "(70% should go to app1, 30% should go to app2)"

# Create temp file for tracking
temp_canary=$(mktemp)

# Make 20 requests to canary endpoint
for i in {1..20}; do
    echo -n "."
    response=$(curl -s -H "Host: app1.local" http://localhost:8080/canary)
    hostname=$(echo "$response" | jq -r '.environment.HOSTNAME' 2>/dev/null)
    
    # Determine which service based on hostname pattern
    if [[ "$hostname" == app1-* ]]; then
        echo "app1" >> "$temp_canary"
    elif [[ "$hostname" == app2-* ]]; then
        echo "app2" >> "$temp_canary"
    fi
    sleep 0.2
done

echo ""
echo ""
echo "Canary routing results:"
sort "$temp_canary" | uniq -c | sort -nr

# Calculate percentages
total_canary=$(wc -l < "$temp_canary")
app1_count=$(grep -c "app1" "$temp_canary" 2>/dev/null || echo 0)
app2_count=$(grep -c "app2" "$temp_canary" 2>/dev/null || echo 0)

if [ "$total_canary" -gt 0 ]; then
    app1_percent=$(echo "scale=1; $app1_count * 100 / $total_canary" | bc 2>/dev/null || echo "N/A")
    app2_percent=$(echo "scale=1; $app2_count * 100 / $total_canary" | bc 2>/dev/null || echo "N/A")
    echo ""
    echo "Distribution:"
    echo "  app1: $app1_count/$total_canary requests (${app1_percent}%)"
    echo "  app2: $app2_count/$total_canary requests (${app2_percent}%)"
    echo ""
    echo "Expected: ~70% app1, ~30% app2"
fi

rm -f "$temp_canary"

# Test regular path still works
echo ""
echo "Verifying regular path still load balances across app1 pods..."
temp_regular=$(mktemp)

for i in {1..10}; do
    curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null >> "$temp_regular"
    sleep 0.2
done

echo "Regular path (/) distribution:"
sort "$temp_regular" | uniq -c

# Check that all are app1 pods
unique_pods=$(sort "$temp_regular" | uniq | wc -l)
echo "Unique app1 pods responding: $unique_pods"

rm -f "$temp_regular"

echo ""
echo "========================================================"
echo "Weighted routing test completed!"
echo ""
echo "To restore original routing:"
echo "  kubectl apply -f manifests/part2/http-route.yaml"