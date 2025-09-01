# Kubernetes Gateway API POC

[🇺🇸 English](README.md) | [🇮🇩 Bahasa Indonesia](README-ID.md)

---

Proof of Concept for implementing Kubernetes Gateway API using Kind (Kubernetes in Docker) with NGINX Gateway Fabric for learning and research of Gateway API fundamentals.

## 🎯 POC Objectives

This POC is designed to understand fundamental Kubernetes Gateway API concepts through progressive practical implementation:

1. **Part 1**: Environment setup with Kind and NGINX Gateway Fabric
2. **Part 2**: Basic HTTP routing with host and path-based routing  
3. **Part 3**: Load balancing and advanced routing features
4. **Part 4**: gRPC routing and protocol-specific routing

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client    │───▶│   Kind Cluster  │───▶│   Demo Apps     │
│ (localhost) │    │  Gateway API    │    │  HTTP + gRPC    │  
└─────────────┘    └─────────────────┘    └─────────────────┘
   Port 8080           NGINX Gateway         Echo & gRPC
                      Fabric Controller       Services

Parts Coverage:
• Part 1: Cluster Setup
• Part 2: HTTP Routing  
• Part 3: Load Balancing
• Part 4: gRPC Routing
```

## 📋 Prerequisites

### Software Requirements
- **Docker**: 20.10+ with minimum 4GB memory
- **kubectl**: Latest stable version
- **Kind**: v0.20.0+
- **curl**: For HTTP route testing
- **jq**: (Optional) For JSON parsing

### Kind Installation
```bash
go install sigs.k8s.io/kind@v0.20.0
```

## 🚀 Quick Start

### 1. Clone Project
```bash
git clone <repository-url>
cd poc-kgateway
```

### 2. Run Part 1 (Environment Setup)
```bash
# Create Kind cluster
kind create cluster --config manifests/part1/kind-config.yaml

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

# Install NGINX Gateway Fabric
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/default/deploy.yaml

# Verify installation
kubectl get pods -n nginx-gateway
kubectl get gatewayclass
```

### 3. Run Part 2 (Basic HTTP Routing)
```bash
# Automated (Recommended)
./scripts/start-part2.sh

# Manual
kubectl apply -f manifests/part2/
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &
./scripts/test-routing.sh
```

### 4. Run Part 3 (Load Balancing)
```bash
# Automated
./scripts/start-part3.sh

# Test advanced routing
./scripts/test-load-balancing.sh
```

### 5. Run Part 4 (gRPC Routing)
```bash
# Automated
./scripts/start-part4.sh

# Test gRPC routing
./scripts/test-grpc-routing.sh
```

### 6. Test Routing
```bash
# Main app (root path)
curl -H "Host: app1.local" http://localhost:8080/

# Admin app (admin path)
curl -H "Host: app1.local" http://localhost:8080/admin
```

## 📁 Project Structure

```
poc-kgateway/
├── .claude/                      # AI planning and context
├── manifests/                    # Kubernetes YAML files
│   ├── part1/                    # Environment setup
│   │   ├── kind-config.yaml
│   │   └── nginx-gatewayclass.yaml
│   ├── part2/                    # Basic HTTP routing
│   │   ├── app1-deployment.yaml
│   │   ├── app2-deployment.yaml
│   │   ├── gateway.yaml
│   │   └── http-route.yaml
│   ├── part3/                    # Load balancing & advanced routing
│   │   ├── enhanced-deployments.yaml
│   │   ├── weighted-routes.yaml
│   │   └── header-based-routes.yaml
│   └── part4/                    # gRPC routing (NEW!)
│       ├── grpc-health-service.yaml
│       ├── grpc-greeter-service.yaml
│       ├── gateway-grpc.yaml
│       ├── grpc-route.yaml
│       ├── grpc-http-route.yaml
│       └── grpc-client.yaml
├── scripts/                      # Testing and automation scripts
│   ├── start-part2.sh
│   ├── start-part3.sh
│   ├── start-part4.sh           # NEW!
│   ├── cleanup-part2.sh
│   ├── cleanup-part3.sh
│   ├── cleanup-part4.sh         # NEW!
│   ├── test-routing.sh
│   ├── test-load-balancing.sh
│   ├── test-grpc-routing.sh     # NEW!
│   └── test-grpc-load-balancing.sh # NEW!
├── docs/               # Complete documentation
│   ├── 01-how-to-run.md         # POC execution guide
│   ├── 02-concepts-explained.md  # Gateway API concepts explanation
│   ├── 03-code-explained.md     # Implementation code analysis
│   ├── 04-part2-basic-routing.md # Part 2 details
│   ├── 05-part3-load-balancing.md # Part 3 details
│   └── 06-part4-grpc-routing.md  # Part 4 details (NEW!)
├── README.md                     # This file (English)
└── README-ID.md                  # Indonesian documentation
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [How to Run](docs/01-how-to-run.md) | Step-by-step POC execution guide |
| [Concepts Explained](docs/02-concepts-explained.md) | In-depth Gateway API concepts |  
| [Code Explained](docs/03-code-explained.md) | Detailed implementation code analysis |
| [Part 2 - Basic Routing](docs/04-part2-basic-routing.md) | Part 2 specific documentation |
| [Part 3 - Load Balancing](docs/05-part3-load-balancing.md) | Part 3 specific documentation |
| [Part 4 - gRPC Routing](docs/06-part4-grpc-routing.md) | **Part 4 specific documentation (NEW!)** |

## 🧪 Testing

### Test Scripts
```bash
# Test routing functionality
./scripts/test-routing.sh

# Start Part 2 (full deployment)
./scripts/start-part2.sh

# Start Part 3 (load balancing)
./scripts/start-part3.sh

# Start Part 4 (gRPC routing) [NEW!]
./scripts/start-part4.sh

# Advanced routing tests
./scripts/test-load-balancing.sh
./scripts/test-grpc-routing.sh          # NEW!
./scripts/test-grpc-load-balancing.sh   # NEW!

# Cleanup scripts
./scripts/cleanup-part4.sh    # Clean Part 4 [NEW!]
./scripts/cleanup-part3.sh    # Revert to Part 2
./scripts/cleanup-part2.sh    # Remove Part 2
```

### Manual Testing
```bash
# Test main app
curl -H "Host: app1.local" http://localhost:8080/
curl -H "Host: app1.local" http://localhost:8080/api/users

# Test admin app  
curl -H "Host: app1.local" http://localhost:8080/admin
curl -H "Host: app1.local" http://localhost:8080/admin/dashboard

# Test hostname validation (should fail)
curl -H "Host: wrong.local" http://localhost:8080/

# Part 3: Load balancing tests
# Test load distribution
for i in {1..10}; do curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME'; done

# Test weighted routing
curl -H "Host: app1.local" http://localhost:8080/canary

# Test premium user routing
curl -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/api
```

## ✅ Implementation Status

### ✅ Part 1: Environment Setup
- [x] Kind cluster with port mapping (8080→80)
- [x] Gateway API v1.1.0 CRDs
- [x] NGINX Gateway Fabric v1.4.0 controller
- [x] GatewayClass "nginx" ready and accepted

### ✅ Part 2: Basic HTTP Routing  
- [x] Two demo applications (app1 & app2) with echo server
- [x] Gateway resource with HTTP listener
- [x] HTTPRoute with host and path-based routing
- [x] Routing rules: `/` → app1, `/admin` → app2
- [x] Port forwarding for testing
- [x] Automated testing scripts
- [x] Complete documentation

### ✅ Part 3: Load Balancing & Advanced Routing
- [x] Multi-replica deployments (3 pod replicas)
- [x] Load balancing verification across pods
- [x] Advanced routing policies (weighted, header-based)
- [x] Performance monitoring and traffic analysis
- [x] Canary deployment simulation (70/30 split)
- [x] Premium user routing based on headers
- [x] Automated testing scripts
- [x] Comprehensive documentation

### ✅ Part 4: gRPC Routing & Protocol Support **[NEW!]**
- [x] gRPC service deployment (Health + Greeter services)
- [x] Native GRPCRoute implementation with method-based routing
- [x] HTTPRoute fallback for gRPC compatibility
- [x] Gateway HTTP/2 listener configuration
- [x] Service-based routing (`grpc.health.v1.Health`, `helloworld.Greeter`)
- [x] gRPC load balancing across multiple replicas
- [x] Protocol-specific routing verification
- [x] Dual routing approach (GRPCRoute + HTTPRoute)
- [x] Automated testing scripts for gRPC
- [x] Comprehensive gRPC documentation

## 🚀 How to Run

### Option 1: Per Part (Recommended for Learning)
```bash
# Part 1: Setup environment
kind create cluster --config manifests/part1/kind-config.yaml
# ... (see full documentation)

# Part 2: Basic HTTP routing
./scripts/start-part2.sh

# Part 3: Load balancing & advanced routing
./scripts/start-part3.sh

# Part 4: gRPC routing [NEW!]
./scripts/start-part4.sh
```

### Option 2: Full Deployment
```bash
# Complete setup Part 1 + Part 2
# (see docs/01-how-to-run.md)
```

## 🔧 Troubleshooting

### Common Issues
1. **Port 8080 already in use**: Check `lsof -i :8080`, kill process or change port
2. **Pod CrashLoopBackOff**: Check logs `kubectl logs <pod-name>`
3. **Gateway not ready**: Verify NGINX Gateway controller running
4. **404 responses**: Ensure Host header is correct and port forwarding is active

### Debug Commands
```bash
# Check status of all resources
kubectl get pods,services,gateway,httproute

# Check controller logs
kubectl logs -n nginx-gateway -l app=nginx-gateway-controller

# Test connectivity
curl -v -H "Host: app1.local" http://localhost:8080/
```

## 🧹 Cleanup

### Cleanup Part 2 Only
```bash
./scripts/cleanup-part2.sh
```

### Full Cleanup
```bash
kind delete cluster --name gateway-api-poc
```

## 📖 Learning Path

1. **Understand Gateway API concepts** → Read `docs/02-concepts-explained.md`
2. **Setup environment** → Run Part 1
3. **Implement basic routing** → Run Part 2  
4. **Analyze code** → Read `docs/03-code-explained.md`
5. **Explore advanced features** → Run Part 3 & Part 4

## 🎯 Expected Learning Outcomes

After completing this POC, you will understand:

- ✅ Gateway API architecture and components
- ✅ Differences between Gateway API vs Ingress
- ✅ Host-based and path-based routing implementation
- ✅ Role separation (GatewayClass, Gateway, HTTPRoute, GRPCRoute)
- ✅ NGINX Gateway Fabric as implementation
- ✅ Load balancing and traffic management
- ✅ **gRPC routing and protocol-specific routing [NEW!]**
- ✅ **HTTP/2 protocol handling and service-based routing [NEW!]**

## 🤝 Contributing

This POC is a learning project. For improvements or bug fixes:

1. Review existing implementation
2. Test changes with existing scripts
3. Update relevant documentation
4. Ensure backward compatibility

## 📄 License

Educational/Learning purpose. Free to use and modify.

---

**All Parts Completed!** 🎉 

All four parts of the Gateway API POC are now available:
- Part 1: Environment setup ✅
- Part 2: HTTP routing ✅  
- Part 3: Load balancing ✅
- Part 4: gRPC routing ✅

Start your journey with Part 1, then progress through each part to master Kubernetes Gateway API!