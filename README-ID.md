# Kubernetes Gateway API POC

[🇺🇸 English](README.md) | [🇮🇩 Bahasa Indonesia](README-ID.md)

---

Proof of Concept implementasi Kubernetes Gateway API menggunakan Kind (Kubernetes in Docker) dengan NGINX Gateway Fabric untuk pembelajaran dan penelitian dasar-dasar Gateway API.

## 🎯 Tujuan POC

POC ini dirancang untuk memahami konsep fundamental Kubernetes Gateway API melalui implementasi praktis bertahap:

1. **Part 1**: Environment setup dengan Kind dan NGINX Gateway Fabric
2. **Part 2**: HTTP routing dasar dengan host dan path-based routing  
3. **Part 3**: Load balancing dan advanced routing features
4. **Part 4**: gRPC routing dan protocol-specific routing

## 🏗️ Arsitektur

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client    │───▶│   Kind Cluster  │───▶│   Demo Apps     │
│ (localhost) │    │  Gateway API    │    │ HTTP + gRPC     │  
└─────────────┘    └─────────────────┘    └─────────────────┘
   Port 8080           NGINX Gateway         Echo & gRPC
                      Fabric Controller       Services

Cakupan:
• Part 1: Cluster Setup
• Part 2: HTTP Routing  
• Part 3: Load Balancing
• Part 4: gRPC Routing
```

## 📋 Prerequisites

### Kebutuhan Software
- **Docker**: 20.10+ dengan minimum 4GB memory
- **kubectl**: Latest stable version
- **Kind**: v0.20.0+
- **curl**: Untuk testing HTTP routes
- **jq**: (Opsional) Untuk JSON parsing

### Instalasi Kind
```bash
go install sigs.k8s.io/kind@v0.20.0
```

## 🚀 Quick Start

### 1. Clone Project
```bash
git clone <repository-url>
cd poc-kgateway
```

### 2. Jalankan Part 1 (Environment Setup)
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

### 3. Jalankan Part 2 (Basic HTTP Routing)
```bash
# Otomatis (Disarankan)
./scripts/start-part2.sh

# Manual
kubectl apply -f manifests/part2/
kubectl port-forward -n nginx-gateway service/nginx-gateway 8080:80 &
./scripts/test-routing.sh
```

### 4. Jalankan Part 3 (Load Balancing)
```bash
# Otomatis
./scripts/start-part3.sh

# Test advanced routing
./scripts/test-load-balancing.sh
```

### 5. Jalankan Part 4 (gRPC Routing)
```bash
# Otomatis
./scripts/start-part4.sh

# Test gRPC routing
./scripts/test-grpc-routing.sh
```

### 6. Test Routing
```bash
# Aplikasi utama (root path)
curl -H "Host: app1.local" http://localhost:8080/

# Aplikasi admin (admin path)
curl -H "Host: app1.local" http://localhost:8080/admin
```

## 📁 Struktur Project

```
poc-kgateway/
├── .claude/                      # AI planning dan context
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
│   └── part4/                    # gRPC routing (BARU!)
│       ├── grpc-health-service.yaml
│       ├── grpc-greeter-service.yaml
│       ├── gateway-grpc.yaml
│       ├── grpc-route.yaml
│       ├── grpc-http-route.yaml
│       └── grpc-client.yaml
├── scripts/                      # Testing dan automation scripts
│   ├── start-part2.sh
│   ├── start-part3.sh
│   ├── start-part4.sh           # BARU!
│   ├── cleanup-part2.sh
│   ├── cleanup-part3.sh
│   ├── cleanup-part4.sh         # BARU!
│   ├── test-routing.sh
│   ├── test-load-balancing.sh
│   ├── test-grpc-routing.sh     # BARU!
│   └── test-grpc-load-balancing.sh # BARU!
├── docs/               # Dokumentasi lengkap
│   ├── 01-how-to-run.md         # Panduan menjalankan POC
│   ├── 02-concepts-explained.md  # Penjelasan konsep Gateway API
│   ├── 03-code-explained.md     # Analisis implementasi code
│   ├── 04-part2-basic-routing.md # Detail Part 2
│   ├── 05-part3-load-balancing.md # Detail Part 3
│   └── 06-part4-grpc-routing.md  # Detail Part 4 (BARU!)
├── README.md                     # Dokumentasi bahasa Inggris
└── README-ID.md                  # File ini (Bahasa Indonesia)
```

## 📚 Dokumentasi

| Dokumen | Deskripsi |
|---------|-----------|
| [How to Run](docs/01-how-to-run.md) | Panduan langkah-demi-langkah menjalankan POC |
| [Concepts Explained](docs/02-concepts-explained.md) | Penjelasan mendalam konsep Gateway API |  
| [Code Explained](docs/03-code-explained.md) | Analisis detail implementasi code |
| [Part 2 - Basic Routing](docs/04-part2-basic-routing.md) | Dokumentasi khusus Part 2 |
| [Part 3 - Load Balancing](docs/05-part3-load-balancing.md) | Dokumentasi khusus Part 3 |
| [Part 4 - gRPC Routing](docs/06-part4-grpc-routing.md) | **Dokumentasi khusus Part 4 (BARU!)** |

## 🧪 Testing

### Script Testing
```bash
# Test fungsi routing
./scripts/test-routing.sh

# Mulai Part 2 (deployment lengkap)
./scripts/start-part2.sh

# Mulai Part 3 (load balancing)
./scripts/start-part3.sh

# Mulai Part 4 (gRPC routing) [BARU!]
./scripts/start-part4.sh

# Test routing lanjutan
./scripts/test-load-balancing.sh
./scripts/test-grpc-routing.sh          # BARU!
./scripts/test-grpc-load-balancing.sh   # BARU!

# Script cleanup
./scripts/cleanup-part4.sh    # Bersihkan Part 4 [BARU!]
./scripts/cleanup-part3.sh    # Kembali ke Part 2
./scripts/cleanup-part2.sh    # Hapus Part 2
```

### Manual Testing
```bash
# Test main app
curl -H "Host: app1.local" http://localhost:8080/
curl -H "Host: app1.local" http://localhost:8080/api/users

# Test admin app  
curl -H "Host: app1.local" http://localhost:8080/admin
curl -H "Host: app1.local" http://localhost:8080/admin/dashboard

# Test hostname validation (harus gagal)
curl -H "Host: wrong.local" http://localhost:8080/

# Part 3: Load balancing tests
# Test distribusi load
for i in {1..10}; do curl -s -H "Host: app1.local" http://localhost:8080/ | jq -r '.environment.POD_NAME'; done

# Test weighted routing
curl -H "Host: app1.local" http://localhost:8080/canary

# Test premium user routing
curl -H "Host: app1.local" -H "X-User-Type: premium" http://localhost:8080/api
```

## ✅ Status Implementation

### ✅ Part 1: Environment Setup
- [x] Kind cluster dengan port mapping (8080→80)
- [x] Gateway API v1.1.0 CRDs
- [x] NGINX Gateway Fabric v1.4.0 controller
- [x] GatewayClass "nginx" ready dan accepted

### ✅ Part 2: Basic HTTP Routing  
- [x] Dua demo aplikasi (app1 & app2) dengan echo server
- [x] Gateway resource dengan HTTP listener
- [x] HTTPRoute dengan host dan path-based routing
- [x] Routing rules: `/` → app1, `/admin` → app2
- [x] Port forwarding untuk testing
- [x] Automated testing scripts
- [x] Dokumentasi lengkap

### ✅ Part 3: Load Balancing & Advanced Routing
- [x] Multi-replica deployments (3 pod replicas)
- [x] Load balancing verification across pods
- [x] Advanced routing policies (weighted, header-based)
- [x] Performance monitoring dan traffic analysis
- [x] Canary deployment simulation (70/30 split)
- [x] Premium user routing based on headers
- [x] Automated testing scripts
- [x] Comprehensive documentation

### ✅ Part 4: gRPC Routing & Protocol Support **[BARU!]**
- [x] gRPC service deployment (Health + Greeter services)
- [x] Native GRPCRoute implementation dengan method-based routing
- [x] HTTPRoute fallback untuk kompatibilitas gRPC
- [x] Gateway HTTP/2 listener configuration
- [x] Service-based routing (`grpc.health.v1.Health`, `helloworld.Greeter`)
- [x] gRPC load balancing across multiple replicas
- [x] Protocol-specific routing verification
- [x] Dual routing approach (GRPCRoute + HTTPRoute)
- [x] Automated testing scripts untuk gRPC
- [x] Comprehensive gRPC documentation

## 🚀 Cara Menjalankan

### Option 1: Per Part (Disarankan untuk Pembelajaran)
```bash
# Part 1: Setup environment
kind create cluster --config manifests/part1/kind-config.yaml
# ... (lihat dokumentasi lengkap)

# Part 2: Routing HTTP dasar
./scripts/start-part2.sh

# Part 3: Load balancing & routing lanjutan
./scripts/start-part3.sh

# Part 4: gRPC routing [BARU!]
./scripts/start-part4.sh
```

### Option 2: Full Deployment
```bash
# Setup lengkap Part 1 + Part 2
# (lihat docs/01-how-to-run.md)
```

## 🔧 Troubleshooting

### Common Issues
1. **Port 8080 sudah digunakan**: Check `lsof -i :8080`, kill process atau ganti port
2. **Pod CrashLoopBackOff**: Check logs `kubectl logs <pod-name>`
3. **Gateway not ready**: Verify NGINX Gateway controller running
4. **404 responses**: Pastikan Host header benar dan port forwarding aktif

### Debug Commands
```bash
# Check status semua resources
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

1. **Pahami konsep Gateway API** → Baca `docs/02-concepts-explained.md`
2. **Setup environment** → Jalankan Part 1
3. **Implementasi basic routing** → Jalankan Part 2  
4. **Analisis code** → Baca `docs/03-code-explained.md`
5. **Eksplorasi advanced features** → Jalankan Part 3 & Part 4

## 🎯 Hasil Pembelajaran yang Diharapkan

Setelah menyelesaikan POC ini, Anda akan memahami:

- ✅ Arsitektur dan komponen Gateway API
- ✅ Perbedaan Gateway API vs Ingress
- ✅ Implementasi host-based dan path-based routing
- ✅ Role separation (GatewayClass, Gateway, HTTPRoute, GRPCRoute)
- ✅ NGINX Gateway Fabric sebagai implementation
- ✅ Load balancing dan traffic management
- ✅ **gRPC routing dan protocol-specific routing [BARU!]**
- ✅ **HTTP/2 protocol handling dan service-based routing [BARU!]**

## 🤝 Contributing

POC ini adalah learning project. Untuk improvement atau bug fixes:

1. Review existing implementation
2. Test changes dengan existing scripts
3. Update dokumentasi yang relevan
4. Ensure backward compatibility

## 📄 License

Educational/Learning purpose. Free to use and modify.

---

**Semua Part Selesai!** 🎉 

Keempat bagian POC Gateway API telah tersedia:
- Part 1: Environment setup ✅
- Part 2: HTTP routing ✅  
- Part 3: Load balancing ✅
- Part 4: gRPC routing ✅

Mulai perjalanan Anda dengan Part 1, lalu lanjutkan setiap bagian untuk menguasai Kubernetes Gateway API!