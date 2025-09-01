#!/bin/bash

echo "Monitoring Gateway Traffic Distribution"
echo "======================================"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Check if we have multiple replicas
replicas=$(kubectl get deployment app1 -o jsonpath='{.spec.replicas}')
if [ "$replicas" -lt 2 ]; then
    echo "⚠️  Warning: App1 has only $replicas replica(s). For meaningful load balancing monitoring,"
    echo "   consider scaling: kubectl scale deployment app1 --replicas=3"
    echo ""
fi

# Monitor loop
iteration=0
while true; do
    iteration=$((iteration + 1))
    echo "$(date '+%H:%M:%S') - Iteration $iteration: Testing load distribution..."
    
    # Create temp file for this iteration
    temp_monitor=$(mktemp)
    
    # Make concurrent requests
    for i in {1..5}; do
        curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME' 2>/dev/null >> "$temp_monitor" &
    done
    wait
    
    # Show distribution for this iteration
    echo "  Response distribution:"
    sort "$temp_monitor" | uniq -c | sed 's/^/    /'
    
    rm -f "$temp_monitor"
    
    # Show current pod status
    echo "  Active app1 pods:"
    kubectl get pods -l app=app1 --no-headers | awk '{print "    " $1 " - " $3}' 2>/dev/null
    
    # Show service endpoint count
    endpoint_count=$(kubectl get endpoints app1-service --no-headers 2>/dev/null | awk '{print $2}' | tr ',' '\n' | wc -l)
    echo "  Service endpoints: $endpoint_count"
    
    echo "  ---"
    sleep 5
done