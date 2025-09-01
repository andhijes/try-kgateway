# Part 2: Basic HTTP Routing Implementation

## Overview
Part 2 demonstrates fundamental HTTP routing capabilities of Kubernetes Gateway API through host-based and path-based routing rules. This implementation shows how to route traffic to different backend services based on request paths using NGINX Gateway Fabric.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Client        │────▶│   Gateway       │
│ (curl/browser)  │     │  (NGINX GWF)    │
└─────────────────┘     └─────────────────┘
                                 │
                        Host: app1.local
                                 │
                    ┌─────────┬──┴──┐
                    │         │     │
                Path: /      Path: /admin/*
                    │         │     │
                    ▼         ▼     ▼
        ┌─────────────────┐  ┌─────────────────┐
        │     App1        │  │     App2        │
        │ (Main Service)  │  │ (Admin Service) │
        └─────────────────┘  └─────────────────┘
```

## Implementation Details

### Demo Applications

**Application 1 (Main Service)**
- **Purpose**: Handles main application traffic
- **Image**: `ealen/echo-server:latest`
- **Endpoints**: Root path `/` and non-admin paths
- **Service**: `app1-service` on port 80

**Application 2 (Admin Service)**  
- **Purpose**: Handles administrative functions
- **Image**: `ealen/echo-server:latest`
- **Endpoints**: Admin path `/admin` and subpaths
- **Service**: `app2-service` on port 80

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
    allowedRoutes:
      namespaces:
        from: Same
```

**Key Features:**
- **Single Listener**: HTTP on port 80
- **Same Namespace**: Routes must be in same namespace as Gateway
- **Protocol**: HTTP only (no TLS in this part)

### HTTPRoute Configuration

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
spec:
  parentRefs:
  - name: my-gateway
  hostnames:
  - app1.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /admin
    backendRefs:
    - name: app2-service
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: app1-service
      port: 80
```

**Routing Logic:**
1. **Admin Rule (Priority 1)**: `/admin` prefix → app2-service
2. **Default Rule (Priority 2)**: `/` prefix → app1-service

**Path Matching Examples:**
- `GET /` → app1-service
- `GET /api/users` → app1-service  
- `GET /admin` → app2-service
- `GET /admin/dashboard` → app2-service
- `GET /admin/users/123` → app2-service

## Deployment Steps

### Prerequisites
- Part 1 completed (Kind cluster with Gateway API support)
- Port 8080 available on localhost

### Quick Deployment
```bash
# Automated deployment
./scripts/start-part2.sh
```

### Manual Deployment
```bash
# 1. Deploy applications
kubectl apply -f manifests/part2/app1-deployment.yaml
kubectl apply -f manifests/part2/app2-deployment.yaml

# 2. Wait for pods
kubectl wait --for=condition=ready pod -l app=app1 --timeout=60s
kubectl wait --for=condition=ready pod -l app=app2 --timeout=60s

# 3. Create Gateway and Route
kubectl apply -f manifests/part2/gateway.yaml
kubectl apply -f manifests/part2/http-route.yaml

# 4. Start port forwarding
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &

# 5. Test routing
./scripts/test-routing.sh
```

## Testing and Validation

### Test Script Output
```bash
$ ./scripts/test-routing.sh

Testing Kubernetes Gateway API Routing...
===========================================
1. Testing main app (/) ...
GET /
2. Testing admin app (/admin) ...
GET /admin  
3. Testing admin subpath (/admin/users) ...
GET /admin/users
4. Testing main app other path (/api/data) ...
GET /api/data
5. Testing wrong host (should fail) ...
HTTP Status: 404

=========================================
Testing Pod Identification...
=========================================
6. Main app pod identification:
app1-5d6766c6c9-4pvxx
7. Admin app pod identification:
app2-64f8d86888-s8tkh
```

### Manual Testing Commands

#### Basic Routing Tests
```bash
# Main application
curl -H "Host: app1.local" http://localhost:8080/
curl -H "Host: app1.local" http://localhost:8080/api/v1/users

# Admin application  
curl -H "Host: app1.local" http://localhost:8080/admin
curl -H "Host: app1.local" http://localhost:8080/admin/dashboard
curl -H "Host: app1.local" http://localhost:8080/admin/users/123

# Invalid hostname (should return 404)
curl -H "Host: invalid.local" http://localhost:8080/
```

#### Response Analysis
```bash
# Check which pod is responding
curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.HOSTNAME'
curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME'

# View full response
curl -H "Host: app1.local" http://localhost:8080/ | jq
```

## Configuration Options

### Path Matching Types

**1. PathPrefix (Used in POC)**
```yaml
path:
  type: PathPrefix
  value: /admin
```
- Matches: `/admin`, `/admin/`, `/admin/users`
- Most common for microservices

**2. Exact Match**
```yaml
path:
  type: Exact
  value: /admin
```
- Matches: Only `/admin` exactly
- Useful for specific endpoints

**3. Regular Expression**
```yaml
path:
  type: RegularExpression
  value: "^/admin/users/[0-9]+$"
```
- Matches: `/admin/users/123`, `/admin/users/456`
- Advanced pattern matching

### Header Matching
```yaml
matches:
- headers:
  - name: "X-User-Type"
    value: "admin"
  path:
    type: PathPrefix
    value: /admin
```

### Multiple Hostnames
```yaml
hostnames:
- app1.local
- api.app1.local
- admin.app1.local
```

## Advanced Configurations

### Weighted Routing (Blue-Green)
```yaml
backendRefs:
- name: app1-service-v1
  port: 80
  weight: 80
- name: app1-service-v2
  port: 80
  weight: 20
```

### Request Header Modification
```yaml
rules:
- matches:
  - path:
      value: /admin
  filters:
  - type: RequestHeaderModifier
    requestHeaderModifier:
      add:
      - name: "X-Admin-Request"
        value: "true"
  backendRefs:
  - name: app2-service
    port: 80
```

### URL Rewriting
```yaml
filters:
- type: URLRewrite
  urlRewrite:
    path:
      type: ReplacePrefixMatch
      replacePrefixMatch: "/api/v2"
```

## Troubleshooting

### Common Issues

#### 1. 404 Responses
**Symptoms**: All requests return 404
**Causes**:
- Host header not set correctly
- Port forwarding not active
- HTTPRoute not accepted

**Solutions**:
```bash
# Check Host header
curl -v -H "Host: app1.local" http://localhost:8080/

# Verify port forwarding
ps aux | grep port-forward

# Check HTTPRoute status
kubectl get httproute my-route -o yaml
```

#### 2. Wrong Service Response
**Symptoms**: `/admin` routes to main app instead of admin app
**Causes**:
- Rule order incorrect
- Path matching not working

**Solutions**:
```bash
# Check pod responses
curl -s -H "Host: app1.local" http://localhost:8080/admin | jq -r '.environment.HOSTNAME'

# Verify HTTPRoute rules
kubectl describe httproute my-route
```

#### 3. Gateway Not Ready
**Symptoms**: Gateway shows `PROGRAMMED: False`
**Causes**:
- NGINX Gateway controller not running
- GatewayClass not available

**Solutions**:
```bash
# Check controller
kubectl get pods -n nginx-gateway

# Check GatewayClass
kubectl get gatewayclass nginx

# View Gateway status
kubectl describe gateway my-gateway
```

### Debug Commands
```bash
# Check all resources
kubectl get pods,services,gateway,httproute

# View detailed status
kubectl describe gateway my-gateway
kubectl describe httproute my-route

# Check events
kubectl get events --sort-by='.firstTimestamp'

# Controller logs
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller
```

## Resource Specifications

### Pod Resources
```yaml
resources:
  requests:
    memory: "32Mi"
    cpu: "50m"
  limits:
    memory: "64Mi"
    cpu: "100m"
```

**Resource Usage per Pod:**
- **Memory**: ~20MB actual usage
- **CPU**: <10m under light load
- **Total Overhead**: ~100MB for both apps

### Service Configuration
```yaml
spec:
  selector:
    app: app1  # or app2
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

## Security Considerations

### Namespace Isolation
```yaml
allowedRoutes:
  namespaces:
    from: Same  # Only same namespace
```

### Production Enhancements
```yaml
# Cross-namespace with ReferenceGrant
allowedRoutes:
  namespaces:
    from: Selector
    selector:
      matchLabels:
        gateway-access: "true"
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-netpol
spec:
  podSelector:
    matchLabels:
      app: app1
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: nginx-gateway
```

## Performance Characteristics

### Latency
- **Gateway Overhead**: ~2-5ms
- **Pod Response Time**: ~10-50ms
- **Total RTT**: ~20-100ms

### Throughput
- **Single Pod**: ~1000 RPS
- **Gateway Limit**: ~10,000 RPS
- **Bottleneck**: Application pods

### Resource Scaling
```yaml
# Horizontal Pod Autoscaler
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

## Cleanup

### Part 2 Only
```bash
./scripts/cleanup-part2.sh
```

### Manual Cleanup
```bash
# Stop port forwarding
pkill -f "port-forward.*nginx-gateway"

# Remove resources
kubectl delete httproute my-route
kubectl delete gateway my-gateway
kubectl delete deployment app1 app2
kubectl delete service app1-service app2-service
```

## Next Steps

After completing Part 2:
1. **Verify all routing rules work correctly**
2. **Understand path precedence and matching**
3. **Experiment with different hostnames and paths**
4. **Ready for Part 3: Load Balancing and scaling**

Part 2 provides the foundation for understanding Gateway API routing concepts that will be extended in Part 3 with multiple replicas and load balancing features.