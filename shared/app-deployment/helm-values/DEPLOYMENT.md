# Guía de Despliegue de Aplicaciones

## Arquitectura de Despliegue

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │    │   Helm Charts   │    │   Kubernetes    │
│  Infrastructure │    │   Applications  │    │    Workloads    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • OKE Cluster   │───▶│ • Addon AI API  │───▶│ • Pods          │
│ • PostgreSQL    │    │ • Frontend      │    │ • Services      │
│ • Networking    │    │ • Redis (ext)   │    │ • Ingress       │
│ • Load Balancer │    │ • Istio Config  │    │ • ConfigMaps    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Orden de Despliegue

### 1. Infraestructura Base (Terraform)
```bash
cd environments/oci/dev
terraform apply
```
**Crea**: Cluster, DB, Networking, Load Balancer

### 2. Service Mesh (Terraform)
```bash
cd environments/oci/dev/istio
terraform apply
```
**Crea**: Istio, Gateway, VirtualService

### 3. Aplicaciones (Helm)
```bash
# Configurar kubectl
oci ce cluster create-kubeconfig --cluster-id <cluster-id> --file ~/.kube/config

# Crear namespace
kubectl create namespace addon-ai-dev

# Agregar repos Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Desplegar Redis (externo)
helm upgrade --install redis bitnami/redis \
  -f shared/app-deployment/helm-values/dev/redis.yaml \
  -n addon-ai-dev

# Crear secrets
kubectl create secret generic addon-ai-secrets \
  --from-literal=database-url="postgresql://admin:ChangeMe123!@<db-host>:5432/addonaidevdb" \
  -n addon-ai-dev

# Desplegar aplicaciones (cuando tengas los charts)
helm upgrade --install addon-ai-api ./charts/addon-ai-api \
  -f shared/app-deployment/helm-values/dev/addon-ai-api.yaml \
  -n addon-ai-dev

helm upgrade --install addon-ai-frontend ./charts/addon-ai-frontend \
  -f shared/app-deployment/helm-values/dev/addon-ai-frontend.yaml \
  -n addon-ai-dev
```

## Componentes por Capa

### Terraform (Infraestructura)
- ✅ **OKE Cluster**: Kubernetes managed
- ✅ **PostgreSQL**: Autonomous Database
- ✅ **VCN/Subnets**: Networking
- ✅ **Load Balancer**: OCI LB
- ✅ **Istio**: Service Mesh

### Helm (Aplicaciones)
- 🔄 **Addon AI API**: Tu aplicación backend
- 🔄 **Addon AI Frontend**: Tu aplicación frontend  
- 📦 **Redis**: Bitnami chart (externo)
- 📦 **Monitoring**: Prometheus/Grafana (opcional)

### Kubernetes (Runtime)
- **Namespaces**: `addon-ai-{env}`
- **Secrets**: Database credentials
- **ConfigMaps**: App configuration
- **Services**: Internal networking
- **Ingress**: Istio Gateway

## Variables de Entorno por Componente

### API
- `DATABASE_URL`: Desde PostgreSQL (Terraform)
- `REDIS_URL`: Desde Redis (Helm)
- `NODE_ENV`: Por ambiente

### Frontend
- `REACT_APP_API_URL`: URL del API
- `REACT_APP_ENVIRONMENT`: Ambiente actual

## Verificación

```bash
# Verificar infraestructura
kubectl get nodes
kubectl get pods -n addon-ai-dev
kubectl get svc -n addon-ai-dev

# Verificar Istio
kubectl get gateway,virtualservice -n addon-ai-dev
kubectl get pods -n istio-system

# Verificar aplicaciones
curl https://api.dev.addon-ai.com/health
curl https://dev.addon-ai.com
```

## Troubleshooting

### Redis Connection
```bash
# Test Redis connectivity
kubectl run redis-test --rm -i --tty --image redis:alpine -- redis-cli -h redis -p 6379 ping
```

### Database Connection
```bash
# Check database secret
kubectl get secret addon-ai-secrets -n addon-ai-dev -o yaml

# Test database connectivity (from pod)
kubectl exec -it <api-pod> -n addon-ai-dev -- psql $DATABASE_URL -c "SELECT 1"
```