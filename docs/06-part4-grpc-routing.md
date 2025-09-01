# Part 4: gRPC Routing with Gateway API

## 🎯 Overview

Part 4 demonstrates advanced Gateway API capabilities by implementing gRPC routing in a minimal Kind cluster environment. This builds upon Parts 1-3 to show how Gateway API handles gRPC protocol routing and load balancing.

## 📋 Prerequisites

Before starting Part 4, ensure you have completed:
- ✅ Part 1: Environment setup (Kind cluster + NGINX Gateway Fabric)
- ✅ Part 2: Basic HTTP routing
- ✅ Part 3: Load balancing and advanced routing

## 🏗️ Architecture

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ gRPC Client │───▶│   Gateway API    │───▶│  gRPC Services  │
│   (Pod)     │    │ HTTP/2 Listener  │    │ Health + Greeter│
└─────────────┘    │   Port: 8080     │    │   Port: 50051   │
                   └──────────────────┘    └─────────────────┘
                         │
                         ▼
                   ┌──────────────────┐
                   │   GRPCRoute +    │
                   │   HTTPRoute      │
                   │ (Dual Approach)  │
                   └──────────────────┘
```

## 🚀 Quick Start

### Option 1: Automated Deployment
```bash
# Deploy Part 4 with all components
./scripts/start-part4.sh

# Test gRPC routing
./scripts/test-grpc-routing.sh

# Test load balancing
./scripts/test-grpc-load-balancing.sh
```

### Option 2: Manual Step-by-Step

#### Step 1: Deploy gRPC Services
```bash
# Deploy gRPC health service (2 replicas)
kubectl apply -f manifests/part4/grpc-health-service.yaml

# Deploy gRPC greeter service (1 replica)
kubectl apply -f manifests/part4/grpc-greeter-service.yaml

# Verify deployments
kubectl get pods -l 'app in (grpc-health,grpc-greeter)'
```

#### Step 2: Configure Gateway
```bash
# Update gateway with HTTP/2 listener
kubectl apply -f manifests/part4/gateway-grpc.yaml

# Verify gateway configuration
kubectl describe gateway my-gateway
```

#### Step 3: Deploy gRPC Routes
```bash
# Apply native GRPCRoute (primary)
kubectl apply -f manifests/part4/grpc-route.yaml

# Apply HTTPRoute fallback
kubectl apply -f manifests/part4/grpc-http-route.yaml

# Check route status
kubectl get grpcroute,httproute | grep grpc
```

#### Step 4: Deploy Test Client
```bash
# Deploy gRPC client pod
kubectl apply -f manifests/part4/grpc-client.yaml

# Wait for readiness
kubectl wait --for=condition=ready pod grpc-client --timeout=60s
```

## 🔧 Technical Implementation

### gRPC Service Configuration

#### Health Service
- **Image**: Alpine with socat (mock gRPC server)
- **Port**: 50051
- **Service**: `grpc.health.v1.Health`
- **Replicas**: 2 (for load balancing demonstration)

#### Greeter Service
- **Image**: Alpine with socat (mock gRPC server)
- **Port**: 50051
- **Service**: `helloworld.Greeter`
- **Replicas**: 1

### Gateway Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
  - name: grpc        # New gRPC listener
    port: 8080
    protocol: HTTP2   # gRPC requires HTTP/2
```

### Dual Routing Approach

#### 1. Native GRPCRoute (Primary)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - method:
        service: grpc.health.v1.Health
        method: Check
    backendRefs:
    - name: grpc-health-service
      port: 50051
```

#### 2. HTTPRoute Fallback
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
spec:
  parentRefs:
  - name: my-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /grpc.health.v1.Health/
    backendRefs:
    - name: grpc-health-service
      port: 50051
```

## 🧪 Testing & Verification

### Basic Connectivity Tests
```bash
# Test direct service connectivity
kubectl exec grpc-client -- nc -zv grpc-health-service 50051
kubectl exec grpc-client -- nc -zv grpc-greeter-service 50051

# Test gateway connectivity
export GATEWAY_IP=$(kubectl get service nginx-gateway -n nginx-gateway -o jsonpath='{.spec.clusterIP}')
kubectl exec grpc-client -- nc -zv $GATEWAY_IP 80
```

### Route Configuration Tests
```bash
# Check gateway status
kubectl get gateway my-gateway -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'

# Check GRPCRoute status
kubectl get grpcroute grpc-route -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'

# Check service endpoints
kubectl get endpoints grpc-health-service grpc-greeter-service
```

### Load Balancing Tests
```bash
# Scale health service
kubectl scale deployment grpc-health --replicas=3

# Verify scaling
kubectl get pods -l app=grpc-health -o wide

# Check endpoint distribution
kubectl get endpoints grpc-health-service
```

## 📊 Expected Results

### Successful Deployment Indicators
- ✅ Gateway status: `Programmed: True`
- ✅ GRPCRoute status: `Accepted: True`
- ✅ All pods: `Running` state
- ✅ Services have active endpoints
- ✅ Network connectivity tests pass

### Sample Output
```bash
$ ./scripts/test-grpc-routing.sh

Testing gRPC Service Routing via Gateway API
=============================================

✅ Health service direct connectivity: PASSED
✅ Greeter service direct connectivity: PASSED
✅ Gateway programmed: PASSED
✅ GRPCRoute accepted: PASSED
✅ Gateway HTTP connectivity: PASSED

Health service endpoints:
grpc-health-service   10.244.0.17:50051,10.244.0.18:50051,10.244.0.21:50051
```

## 🔍 Key Features Demonstrated

### 1. gRPC Protocol Support
- HTTP/2 protocol handling
- gRPC service and method routing
- Protocol-specific path matching

### 2. Service-Based Routing
- Route by gRPC service names (`grpc.health.v1.Health`, `helloworld.Greeter`)
- Method-specific routing (`Check`, `SayHello`)
- Package namespace awareness

### 3. Load Balancing
- Multiple replicas distribution
- Connection-level load balancing
- Service endpoint management

### 4. Dual Implementation Approach
- Native GRPCRoute for optimal performance
- HTTPRoute fallback for compatibility
- Seamless protocol bridging

## 🚨 Troubleshooting

### Common Issues

#### 1. GRPCRoute Not Accepted
```bash
# Check route status
kubectl describe grpcroute grpc-route

# Verify method fields are present
# Error: "method is required"
# Solution: Ensure both service and method are specified
```

#### 2. Services Not Starting
```bash
# Check pod status
kubectl get pods -l 'app in (grpc-health,grpc-greeter)'

# Check logs
kubectl logs -l app=grpc-health

# Common issue: Image pull errors with mock services
```

#### 3. Gateway Configuration Issues
```bash
# Check gateway listeners
kubectl describe gateway my-gateway

# Verify HTTP/2 protocol support
kubectl logs -n nginx-gateway -l app.kubernetes.io/name=nginx-gateway --tail=20
```

### Debug Commands
```bash
# Full system status
kubectl get pods,services,gateway,grpcroute,httproute

# Network troubleshooting
kubectl exec grpc-client -- nslookup grpc-health-service
kubectl exec grpc-client -- netstat -an | grep 50051

# Configuration validation
kubectl get grpcroute grpc-route -o yaml
kubectl get httproute grpc-http-route -o yaml
```

## 📈 Performance Considerations

### Resource Usage
- **Minimal setup**: ~200Mi memory, ~200m CPU total
- **Mock services**: Low resource footprint
- **Gateway overhead**: Minimal for gRPC routing

### Scaling Strategies
```bash
# Scale services based on load
kubectl scale deployment grpc-health --replicas=5

# Monitor resource usage
kubectl top pods -l 'app in (grpc-health,grpc-greeter)'

# Check gateway performance
kubectl logs -n nginx-gateway -l app.kubernetes.io/name=nginx-gateway | grep -i grpc
```

## 🧹 Cleanup

### Remove Part 4 Only
```bash
# Automated cleanup
./scripts/cleanup-part4.sh

# Manual cleanup
kubectl delete -f manifests/part4/
kubectl scale deployment grpc-health --replicas=0
```

### Complete Environment Cleanup
```bash
# Remove entire cluster
kind delete cluster --name gateway-api-poc
```

## 🎓 Learning Outcomes

After completing Part 4, you should understand:

### Technical Concepts
- ✅ gRPC protocol over HTTP/2
- ✅ Gateway API gRPC routing capabilities
- ✅ Service-based vs path-based routing
- ✅ Load balancing for gRPC connections
- ✅ Dual routing approach benefits

### Implementation Skills
- ✅ Configuring Gateway HTTP/2 listeners
- ✅ Creating GRPCRoute resources
- ✅ Testing gRPC connectivity
- ✅ Debugging routing issues
- ✅ Scaling gRPC services

### Operational Knowledge
- ✅ gRPC service deployment patterns
- ✅ Gateway configuration management
- ✅ Network troubleshooting techniques
- ✅ Performance monitoring approaches

## 🔗 Next Steps

### Production Considerations
1. **Real gRPC Services**: Replace mock services with actual gRPC applications
2. **Security**: Implement TLS termination and authentication
3. **Monitoring**: Add metrics and logging for gRPC traffic
4. **Advanced Routing**: Header-based routing, canary deployments

### Further Learning
1. **Protocol Buffers**: Understanding gRPC service definitions
2. **gRPC Streaming**: Implementing streaming services
3. **Service Mesh**: Integration with Istio or Linkerd
4. **Observability**: Distributed tracing for gRPC calls

---

**Part 4 Complete!** 🎉

Your Kubernetes Gateway API journey now includes comprehensive gRPC routing capabilities, demonstrating the full power of modern API gateway patterns in cloud-native environments.