#!/bin/bash

echo "Testing Kubernetes Gateway API Routing..."
echo "==========================================="

# Test main app root path
echo "1. Testing main app (/) ..."
curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.http.method + " " + .http.uri' 2>/dev/null || echo "Request failed"

# Test admin app
echo "2. Testing admin app (/admin) ..."
curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.http.method + " " + .http.uri' 2>/dev/null || echo "Request failed"

# Test admin subpath
echo "3. Testing admin subpath (/admin/users) ..."
curl -s -H "Host: app1.local" http://localhost:8080/admin/users | jq -r '.http.method + " " + .http.uri' 2>/dev/null || echo "Request failed"

# Test main app other path
echo "4. Testing main app other path (/api/data) ..."
curl -s -H "Host: app1.local" http://localhost:8080/api/data | jq -r '.http.method + " " + .http.uri' 2>/dev/null || echo "Request failed"

# Test wrong host
echo "5. Testing wrong host (should fail) ..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" -H "Host: wrong.local" http://localhost:8080/

echo ""
echo "========================================="
echo "Testing Pod Identification..."
echo "========================================="

# Test which pod is responding - main app
echo "6. Main app pod identification:"
curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "Request failed"

# Test which pod is responding - admin app  
echo "7. Admin app pod identification:"
curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME' 2>/dev/null || echo "Request failed"

echo ""
echo "========================================="
echo "Routing tests completed!"