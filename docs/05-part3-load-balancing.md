# Part 3: Load Balancing & Advanced Routing Implementation

## Overview
Part 3 demonstrates advanced traffic management capabilities of Kubernetes Gateway API, focusing on load balancing across multiple pod replicas and sophisticated routing patterns. This implementation showcases how Gateway API handles traffic distribution, weighted routing, and header-based routing using NGINX Gateway Fabric.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Client        │────▶│   Gateway       │
│ (curl/browser)  │     │  (NGINX GWF)    │
└─────────────────┘     └─────────────────┘
                                 │
                        Host: app1.local
                                 │
                    ┌─────────┬──┴────────┬─────────┐
                    │         │           │         │
                Path: /    Path: /admin  Path: /canary  Headers
                    │         │           │         │
                    ▼         ▼           ▼         ▼
        ┌─────────────────┐  ┌─────────┐  ┌──────────────┐
        │ App1 Replicas   │  │  App2   │  │   Weighted   │
        │  ┌────┬────┬────┤  │         │  │   Routing    │
        │  │Pod1│Pod2│Pod3││  │ (Admin) │  │  70% / 30%   │
        │  └────┴────┴────┘│  └─────────┘  └──────────────┘
        └─────────────────┘
          Load Balanced
```

## Key Features Demonstrated

### 1. Pod Scaling and Load Balancing
- **Multi-replica deployment**: Scale app1 to 3+ replicas
- **Service discovery**: Kubernetes automatically discovers new pods
- **Load distribution**: Gateway distributes traffic across all healthy pods
- **Pod identification**: Enhanced logging shows which pod handles each request

### 2. Advanced Routing Patterns
- **Weighted routing**: Canary deployments with traffic splitting
- **Header-based routing**: Premium user routing based on HTTP headers
- **Path precedence**: Complex routing rule prioritization
- **Service isolation**: Admin functionality remains isolated

### 3. Traffic Management
- **Concurrent request handling**: Multiple simultaneous requests
- **Performance monitoring**: Response time measurement
- **Resource tracking**: Pod resource utilization
- **Health monitoring**: Pod status and readiness

## Implementation Details

### Enhanced Application Deployment

**File**: `manifests/part3/app1-enhanced.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 3  # Scaled for load balancing
  template:
    spec:
      containers:
      - name: echo-server
        env:
        - name: ECHO__ENABLE__ENVIRONMENT
          value: "true"  # Enable pod info visibility
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

**Key Enhancements:**
- **Pod Identification**: `POD_NAME` shows in responses for load balancing verification
- **Network Info**: `POD_IP` for debugging network issues  
- **Node Awareness**: `NODE_NAME` for multi-node cluster scenarios
- **Environment Visibility**: Full environment variables in responses

### Weighted Routing Configuration

**File**: `manifests/part3/weighted-route.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route-weighted
spec:
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /canary
    backendRefs:
    - name: app1-service
      port: 80
      weight: 70    # 70% traffic to main service
    - name: app2-service
      port: 80
      weight: 30    # 30% traffic to canary service
```

**Use Cases:**
- **Canary Deployments**: Gradual rollout of new versions
- **A/B Testing**: Split traffic between different implementations
- **Blue-Green Transitions**: Weighted migration between versions
- **Performance Testing**: Controlled load distribution

### Header-Based Routing Configuration

**File**: `manifests/part3/header-based-route.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route-headers
spec:
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
      headers:
      - name: X-User-Type
        value: premium
    backendRefs:
    - name: app2-service  # Premium users → admin backend
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: app1-service  # Regular users → main backend
      port: 80
```

**Applications:**
- **User Tier Routing**: Premium vs standard users
- **Feature Flags**: Route based on client capabilities
- **API Versioning**: Route based on version headers
- **Geographic Routing**: Route based on location headers

## Deployment and Testing

### Quick Start
```bash
# Automated Part 3 setup
./scripts/start-part3.sh
```

### Manual Deployment
```bash
# 1. Scale application to multiple replicas
kubectl scale deployment app1 --replicas=3
kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s

# 2. Apply enhanced deployment
kubectl apply -f manifests/part3/app1-enhanced.yaml
kubectl rollout status deployment/app1

# 3. Test basic load balancing
./scripts/test-load-balancing.sh

# 4. Run comprehensive tests
./scripts/test-advanced-routing.sh
```

## Testing Scenarios

### 1. Basic Load Balancing Test

**Script**: `./scripts/test-load-balancing.sh`

**Expected Output**:
```
Testing Load Balancing Across Multiple Pods
===========================================
Making 15 requests to see load distribution...
Request 1: app1-5b756c64bb-89p9j
Request 2: app1-5b756c64bb-m7dvp
Request 3: app1-5b756c64bb-2jthp
...

Current app1 pods:
app1-5b756c64bb-2jthp - Running
app1-5b756c64bb-89p9j - Running  
app1-5b756c64bb-m7dvp - Running

Total endpoints: 3
```

### 2. Advanced Routing Analysis

**Script**: `./scripts/test-advanced-routing.sh`

**Key Metrics**:
- **Distribution Analysis**: Shows requests per pod with percentages
- **Concurrent Testing**: Validates under load
- **Performance Timing**: Measures response times
- **Service Isolation**: Confirms admin routing still works

### 3. Weighted Routing Test

**Script**: `./scripts/test-weighted-routing.sh`

**Scenario**: 70/30 traffic split for canary deployment
```bash
# Test canary endpoint
curl -H "Host: app1.local" http://localhost:8080/canary

# Expected: ~70% app1 responses, ~30% app2 responses
```

### 4. Header-Based Routing Test  

**Script**: `./scripts/test-header-routing.sh`

**Scenarios**:
```bash
# Premium user (should route to app2)
curl -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/api

# Regular user (should route to app1)  
curl -H "Host: app1.local" http://localhost:8080/api
```

## Performance Analysis

### Load Distribution Patterns

**Even Distribution** (Ideal):
```
Pod A: 7 requests (35%)
Pod B: 6 requests (30%)  
Pod C: 7 requests (35%)
```

**Uneven Distribution** (Normal for small samples):
```
Pod A: 10 requests (50%)
Pod B: 5 requests (25%)
Pod C: 5 requests (25%)
```

### Response Time Analysis

**Typical Response Times**:
- **Gateway Overhead**: 2-10ms
- **Pod Processing**: 10-100ms
- **Network Latency**: 1-5ms
- **Total Round Trip**: 20-200ms

**Performance Factors**:
- **Pod Resource Limits**: CPU/memory constraints
- **Network Conditions**: Cluster network performance
- **Request Complexity**: Echo server processing time
- **Concurrent Load**: Multiple simultaneous requests

### Resource Utilization

**Pod Resources (per replica)**:
```yaml
resources:
  requests:
    memory: "32Mi"    # ~20MB actual usage
    cpu: "50m"        # ~10m actual usage
  limits:
    memory: "64Mi"    # Maximum allowed
    cpu: "100m"       # Maximum allowed
```

**Total Resource Impact**:
- **3 Replicas**: ~60MB memory, ~30m CPU
- **Gateway Controller**: ~100MB memory, ~50m CPU  
- **Total Overhead**: ~160MB memory, ~80m CPU

## Advanced Configurations

### Horizontal Pod Autoscaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app1-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app1
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Load Balancing Algorithms

**NGINX Gateway Fabric** supports various load balancing methods:

1. **Round Robin** (default): Distributes evenly across pods
2. **Least Connections**: Routes to pod with fewest active connections
3. **IP Hash**: Consistent routing based on client IP
4. **Weighted**: Manual traffic distribution control

### Session Affinity (Limited Support)

```yaml
# Note: Session affinity support varies by implementation
backendRefs:
- name: app1-service
  port: 80
  weight: 100
sessionAffinity:
  type: Cookie
  cookie:
    name: gateway-session
    maxAge: 3600
```

## Monitoring and Observability

### Traffic Monitoring Script

**Script**: `./scripts/monitor-traffic.sh`

**Features**:
- **Real-time monitoring**: Continuous traffic distribution tracking
- **Concurrent requests**: Shows load balancing under concurrent load
- **Pod health status**: Displays current pod states
- **Service endpoints**: Shows service discovery status

### Metrics Collection

**Key Metrics to Monitor**:
- **Request Distribution**: Requests per pod over time
- **Response Times**: Latency across different pods
- **Error Rates**: Failed requests per pod
- **Resource Usage**: CPU/memory consumption per pod

### Debug Information

**Pod Details**:
```bash
# Detailed pod information
kubectl get pods -l app=app1 -o wide

# Pod resource usage (if metrics-server available)
kubectl top pods -l app=app1

# Service endpoint status
kubectl get endpoints app1-service -o yaml
```

**Gateway Status**:
```bash
# Gateway configuration
kubectl describe gateway my-gateway

# HTTPRoute status
kubectl get httproute -o yaml

# Controller logs
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller
```

## Scaling Scenarios

### Scale Up Testing
```bash
# Scale to 5 replicas
kubectl scale deployment app1 --replicas=5
kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s

# Test with more replicas
./scripts/test-load-balancing.sh
```

### Scale Down Testing
```bash
# Scale back to 1 replica
kubectl scale deployment app1 --replicas=1

# Verify single pod handling
./scripts/test-load-balancing.sh
```

### Auto-scaling Integration
```bash
# Install metrics server (if not available)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create HPA
kubectl autoscale deployment app1 --cpu-percent=70 --min=2 --max=10
```

## Troubleshooting

### Common Issues

#### 1. Uneven Load Distribution
**Symptoms**: One pod receiving most requests
**Causes**: 
- Small sample size (normal)
- Pod startup timing
- Service endpoint propagation delay

**Solutions**:
```bash
# Verify all pods are ready
kubectl get pods -l app=app1

# Check service endpoints
kubectl get endpoints app1-service

# Wait longer between requests
# Increase request count in tests
```

#### 2. Some Pods Not Receiving Traffic
**Symptoms**: Only subset of pods responding
**Causes**:
- Pods not ready
- Service selector mismatch
- Network connectivity issues

**Debug Steps**:
```bash
# Check pod readiness
kubectl describe pods -l app=app1

# Verify service selector
kubectl get service app1-service -o yaml

# Test pod connectivity directly
kubectl exec -it <pod-name> -- curl localhost:80
```

#### 3. Weighted Routing Not Working
**Symptoms**: Traffic not split according to weights
**Causes**:
- HTTPRoute not applied correctly
- Implementation limitations
- Caching effects

**Solutions**:
```bash
# Verify HTTPRoute status
kubectl describe httproute my-route-weighted

# Check for implementation support
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller

# Test with larger request samples
```

#### 4. Header-Based Routing Issues
**Symptoms**: Headers not affecting routing
**Causes**:
- Header name/value mismatch
- Rule ordering problems
- Case sensitivity

**Debug**:
```bash
# Verify headers in response
curl -v -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/api

# Check HTTPRoute configuration
kubectl get httproute my-route-headers -o yaml
```

## Performance Optimization

### Resource Tuning
```yaml
resources:
  requests:
    memory: "64Mi"    # Increase if pods restart due to OOM
    cpu: "100m"       # Increase if high CPU wait times
  limits:
    memory: "128Mi"   # Increase for memory-intensive apps
    cpu: "200m"       # Increase for CPU-intensive apps
```

### Connection Management
- **Keep-Alive**: Enable HTTP keep-alive for better performance
- **Connection Pooling**: Use connection pools in clients
- **Request Batching**: Batch multiple requests when possible

### Gateway Tuning
- **Worker Processes**: Adjust NGINX worker processes
- **Buffer Sizes**: Tune buffer sizes for larger requests
- **Connection Limits**: Set appropriate connection limits

## Cleanup and Restoration

### Part 3 Cleanup
```bash
# Automated cleanup
./scripts/cleanup-part3.sh

# Manual cleanup
kubectl scale deployment app1 --replicas=1
kubectl apply -f manifests/part2/app1-deployment.yaml
kubectl apply -f manifests/part2/http-route.yaml
```

### Complete Cleanup
```bash
# Remove all POC resources
./scripts/cleanup-part2.sh

# Remove cluster
kind delete cluster --name gateway-api-poc
```

## Learning Outcomes

After completing Part 3, you will understand:

- ✅ **Load Balancing**: How Gateway API distributes traffic across replicas
- ✅ **Scaling Impact**: How pod scaling affects traffic distribution
- ✅ **Advanced Routing**: Weighted and header-based routing patterns
- ✅ **Performance Monitoring**: How to measure and analyze Gateway performance
- ✅ **Canary Deployments**: Traffic splitting for gradual rollouts
- ✅ **User Segmentation**: Header-based routing for different user types
- ✅ **Service Isolation**: Maintaining separation between different services
- ✅ **Resource Management**: Scaling and resource optimization strategies

## Next Steps

**Production Considerations**:
1. **Monitoring Setup**: Implement proper observability stack
2. **Security Policies**: Add authentication and authorization
3. **TLS Configuration**: Enable HTTPS and certificate management
4. **Rate Limiting**: Implement request rate limiting
5. **Circuit Breaking**: Add resilience patterns

**Advanced Features**:
1. **Multi-cluster routing**: Cross-cluster traffic management
2. **Service mesh integration**: Combine with service mesh solutions
3. **Custom policies**: Implement custom routing policies
4. **Advanced load balancing**: Explore sophisticated algorithms

**Real-world Applications**:
1. **Microservices architecture**: Apply to production microservices
2. **API gateway patterns**: Implement enterprise API gateway
3. **Multi-tenant systems**: Route based on tenant information
4. **Geographic distribution**: Region-based routing

Part 3 completes the comprehensive Gateway API learning journey, providing practical experience with advanced traffic management patterns that form the foundation of modern cloud-native applications.