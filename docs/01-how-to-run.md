# How to Run Kubernetes Gateway API POC

## Overview
This document provides step-by-step instructions to run the Kubernetes Gateway API Proof of Concept using Kind (Kubernetes in Docker). The POC is designed to demonstrate Gateway API fundamentals through three progressive parts.

## Prerequisites

### Required Software
- **Docker**: Version 20.10+ with at least 4GB memory allocated
- **kubectl**: Latest stable version
- **Kind**: Version 0.20.0+
  ```bash
  go install sigs.k8s.io/kind@v0.20.0
  ```
- **curl**: For testing HTTP routes
- **jq**: (Optional) For JSON parsing in test scripts

### System Requirements
- **Memory**: At least 4GB RAM available for Docker
- **Ports**: Ensure ports 8080 and 8443 are free on localhost
- **Network**: Internet connection for pulling container images

## Quick Start

### 1. Clone and Setup Project
```bash
git clone <your-repo>
cd poc-kgateway
```

### 2. Run Part 1: Environment Setup
```bash
# Create Kind cluster with Gateway API support
kind create cluster --config manifests/part1/kind-config.yaml

# Install Gateway API CRDs (latest version)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

# Install NGINX Gateway Fabric CRDs
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml

# Install NGINX Gateway Fabric Controller
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/default/deploy.yaml

# Verify installation
kubectl get pods -n nginx-gateway
kubectl get gatewayclass
```

**Expected Output:**
- NGINX Gateway pod: `2/2 Running`  
- GatewayClass status: `ACCEPTED: True`

### 3. Run Part 2: Basic HTTP Routing

#### Option A: Automated Script (Recommended)
```bash
# Run the complete Part 2 setup
./scripts/start-part2.sh
```

#### Option B: Manual Steps
```bash
# Deploy demo applications
kubectl apply -f manifests/part2/app1-deployment.yaml
kubectl apply -f manifests/part2/app2-deployment.yaml

# Create Gateway and HTTPRoute
kubectl apply -f manifests/part2/gateway.yaml
kubectl apply -f manifests/part2/http-route.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=app1 --timeout=60s
kubectl wait --for=condition=ready pod -l app=app2 --timeout=60s

# Port forward for testing (keep running in separate terminal)
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &

# Test routing
curl -H "Host: app1.local" http://localhost:8080/
curl -H "Host: app1.local" http://localhost:8080/admin

# Run automated tests
./scripts/test-routing.sh
```

**Expected Output:**
- App1 pod: `1/1 Running`
- App2 pod: `1/1 Running`  
- Gateway status: `PROGRAMMED: True`
- HTTPRoute: Routes configured with hostnames `["app1.local"]`
- Root path `/` routes to app1
- Admin path `/admin` routes to app2

### 4. Run Part 3: Load Balancing & Advanced Routing

#### Option A: Automated Script (Recommended)
```bash
# Run complete Part 3 setup
./scripts/start-part3.sh
```

#### Option B: Manual Steps
```bash
# Scale application to multiple replicas
kubectl scale deployment app1 --replicas=3

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s

# Apply enhanced deployment
kubectl apply -f manifests/part3/app1-enhanced.yaml

# Test basic load balancing
./scripts/test-load-balancing.sh

# Test comprehensive routing
./scripts/test-advanced-routing.sh

# Test advanced routing patterns
./scripts/test-weighted-routing.sh      # Canary deployment (70/30 split)
./scripts/test-header-routing.sh       # Premium user routing
```

**Expected Output:**
- App1 scaled to 3 replicas (all Running)
- Load balancing across multiple pods (different POD_NAME values)
- Weighted routing working (70/30 traffic split)
- Header-based routing working (premium users → app2)
- Performance metrics showing response times

## Detailed Commands

### Environment Setup Verification
```bash
# Check cluster info
kubectl cluster-info --context kind-gateway-api-poc

# Verify all CRDs are installed
kubectl get crd | grep gateway

# Check controller logs (if needed)
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller

# Resource usage monitoring
kubectl top nodes
kubectl top pods -A
```

### Testing Commands
```bash
# Basic connectivity test
curl -H "Host: app1.local" http://localhost:8080/ | jq

# Path-based routing tests
curl -H "Host: app1.local" http://localhost:8080/admin | jq
curl -H "Host: app1.local" http://localhost:8080/api/data | jq

# Load balancing verification (run multiple times)
for i in {1..10}; do
  curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME'
done
```

### Port Forward Management
```bash
# Start port forwarding
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &

# Check port forwarding process
ps aux | grep port-forward

# Stop port forwarding
pkill -f "port-forward.*nginx-gateway"
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Kind Cluster Creation Fails
```bash
# Check Docker status
docker ps

# Clean up and retry
kind delete cluster --name gateway-api-poc
kind create cluster --config manifests/part1/kind-config.yaml --wait 5m
```

#### 2. NGINX Gateway Pod CrashLoopBackOff
```bash
# Check controller logs
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller

# Common fix: Restart the deployment
kubectl rollout restart deployment/nginx-gateway -n nginx-gateway
```

#### 3. Port Conflicts (8080/8443 in use)
```bash
# Check what's using the ports
lsof -i :8080
lsof -i :8443

# Kill conflicting processes or change ports in kind-config.yaml
```

#### 4. Gateway Not Accepting Routes
```bash
# Check Gateway status
kubectl describe gateway my-gateway

# Check HTTPRoute status  
kubectl describe httproute my-route

# Verify GatewayClass
kubectl get gatewayclass nginx -o yaml
```

#### 5. Applications Not Responding
```bash
# Check application pods
kubectl get pods -l app=app1
kubectl get pods -l app=app2

# Check service endpoints
kubectl get endpoints app1-service app2-service

# Check service connectivity
kubectl exec -it <pod-name> -- curl app1-service

# Test internal routing
kubectl exec -it $(kubectl get pods -l app=app1 -o name | head -1) -- curl app2-service
```

#### 6. Routing Not Working Correctly
```bash
# Check HTTPRoute status
kubectl get httproute my-route -o yaml

# Verify Gateway is accepting routes
kubectl describe gateway my-gateway

# Check if hostname matches
curl -v -H "Host: app1.local" http://localhost:8080/

# Test without hostname (should fail)
curl -v http://localhost:8080/
```

#### 7. Path Routing Issues
```bash
# Test specific paths
curl -H "Host: app1.local" http://localhost:8080/admin/test
curl -H "Host: app1.local" http://localhost:8080/api/test

# Check pod responses to identify which app is responding
curl -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
curl -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME'
```

### Resource Cleanup

#### Part 3 Only (Revert to Part 2)
```bash
# Automated cleanup
./scripts/cleanup-part3.sh
```

#### Part 2 Only (Keep Part 1 Running)
```bash
# Automated cleanup
./scripts/cleanup-part2.sh

# Or manual cleanup
pkill -f "port-forward.*nginx-gateway"
kubectl delete -f manifests/part2/http-route.yaml
kubectl delete -f manifests/part2/gateway.yaml  
kubectl delete -f manifests/part2/app2-deployment.yaml
kubectl delete -f manifests/part2/app1-deployment.yaml
```

#### Complete Cleanup (All Parts)
```bash
# Clean up all POC resources
kubectl delete -f manifests/part3/ --ignore-not-found
kubectl delete -f manifests/part2/ --ignore-not-found

# Remove Kind cluster completely
kind delete cluster --name gateway-api-poc
```

## Performance Monitoring

### Resource Usage Check
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods --all-namespaces

# Check Docker resources
docker stats
```

### Load Testing (Advanced)
```bash
# Install hey (HTTP load testing tool)
go install github.com/rakyll/hey@latest

# Simple load test
hey -n 100 -c 10 -H "Host: app1.local" http://localhost:8080/

# Load test with different paths
hey -n 50 -H "Host: app1.local" http://localhost:8080/admin
```

## Success Criteria Checklist

### Part 1 - Environment Setup
- [ ] Kind cluster running with custom configuration
- [ ] Gateway API CRDs installed and available
- [ ] NGINX Gateway Fabric controller pod running (2/2 Ready)
- [ ] GatewayClass "nginx" accepted and ready
- [ ] Port mappings working (8080→80, 8443→443)

### Part 2 - Basic Routing
- [ ] Two demo applications deployed and running
- [ ] Gateway resource created and ready (PROGRAMMED: True)
- [ ] HTTPRoute resource created and accepted
- [ ] Root path (/) routes to app1 (verify with hostname check)
- [ ] Admin path (/admin) routes to app2 (verify with hostname check)  
- [ ] Admin subpath (/admin/*) routes to app2
- [ ] Non-admin paths route to app1
- [ ] Wrong hostname returns 404 error
- [ ] Port forwarding established successfully
- [ ] Test script runs without errors

### Part 3 - Load Balancing & Advanced Routing
- [ ] App1 scaled to 3+ replicas successfully
- [ ] Load balancing distributes requests across multiple pods
- [ ] Different pod names appear in responses (POD_NAME visibility)
- [ ] All scaled pods receive traffic over multiple requests
- [ ] Weighted routing works (70/30 canary deployment)
- [ ] Header-based routing works (premium user routing)  
- [ ] Advanced test scripts run without errors
- [ ] Performance metrics show acceptable response times
- [ ] Resource usage remains acceptable
- [ ] Gateway maintains stability under concurrent load

## Next Steps

After completing this POC:
1. Explore advanced Gateway API features (TLS, authentication)
2. Test with real applications instead of echo servers
3. Implement monitoring and observability
4. Try different Gateway implementations (Istio, Envoy Gateway)
5. Test in production-like environments

## Support

For issues specific to this POC:
- Check the troubleshooting section above
- Review Kubernetes events: `kubectl get events --sort-by='.firstTimestamp'`
- Check controller logs: `kubectl logs -n nginx-gateway -l app=nginx-gateway-controller`

For Gateway API questions:
- [Kubernetes Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)