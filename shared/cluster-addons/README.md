# Cluster Add-ons

Este directorio contiene configuraciones para herramientas y servicios que se instalan a nivel de cluster de Kubernetes, no específicos de aplicaciones.

## Estructura

```
cluster-addons/
├── monitoring/             # Observabilidad
│   └── prometheus/
│       └── values-dev.yaml
├── security/               # Seguridad del cluster
│   └── cert-manager/
│       └── cluster-issuer.yaml
└── README.md
```

## Add-ons Implementados

### 🔍 Monitoring (Observabilidad)
- **Prometheus**: Métricas del cluster y aplicaciones
- **Grafana**: Dashboards incluidos en Prometheus stack
- **AlertManager**: Alertas incluidas en Prometheus stack

### 🔒 Security (Seguridad)
- **Cert-Manager**: Gestión automática de certificados TLS
- **ClusterIssuer**: Configuración para Let's Encrypt

## Add-ons Futuros (cuando se necesiten)
- **Logging**: Fluentd, Elasticsearch, Kibana
- **External Secrets**: Integración con OCI Vault
- **Ingress NGINX**: Controller alternativo a Istio
- **CSI Drivers**: Drivers personalizados de almacenamiento

## Diferencia con app-deployment

| Directorio | Propósito | Ejemplos |
|------------|-----------|----------|
| `cluster-addons/` | **Infraestructura del cluster** | Prometheus, Cert-Manager, Ingress |
| `app-deployment/` | **Aplicaciones de negocio** | Addon AI API, Frontend, Redis |

## Instalación Típica

### 1. Cert-Manager (TLS automático)
```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### 2. Prometheus Stack (Monitoring)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f shared/cluster-addons/monitoring/prometheus/values.yaml
```

### 3. External Secrets (Secrets management)
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace
```

## Orden de Instalación Actual

1. **Infraestructura**: Terraform (OKE, DB, Networking)
2. **Service Mesh**: Istio (Terraform)
3. **Security**: Cert-Manager (Helm)
4. **Monitoring**: Prometheus Stack (Helm)
5. **Applications**: Addon AI apps (Helm)

## Gestión por Ambiente

Los cluster add-ons pueden tener configuraciones diferentes por ambiente:

```bash
# Dev - Configuración mínima
helm install prometheus -f monitoring/prometheus/values-dev.yaml

# Prod - Configuración completa con HA
helm install prometheus -f monitoring/prometheus/values-prod.yaml
```

## Integración con Istio

Muchos add-ons se integran con Istio:
- **Prometheus**: Scraping de métricas de Istio
- **Grafana**: Dashboards de Istio
- **Jaeger**: Tracing distribuido
- **Cert-Manager**: Certificados para Istio Gateway