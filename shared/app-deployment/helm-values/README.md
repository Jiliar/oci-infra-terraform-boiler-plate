# Helm Values para Aplicaciones Addon AI

Este directorio contiene los archivos de configuración Helm para desplegar las aplicaciones de Addon AI en diferentes ambientes.

## Estructura

```
helm-values/
├── dev/                    # Desarrollo
│   ├── addon-ai-api.yaml
│   ├── addon-ai-frontend.yaml
│   └── redis.yaml
├── test/                   # Testing
│   ├── addon-ai-api.yaml
│   ├── addon-ai-frontend.yaml
│   └── redis.yaml
├── staging/                # Staging
│   ├── addon-ai-api.yaml
│   ├── addon-ai-frontend.yaml
│   └── redis.yaml
├── prod/                   # Producción
│   ├── addon-ai-api.yaml
│   ├── addon-ai-frontend.yaml
│   └── redis.yaml
└── README.md
```

## Aplicaciones

### 1. Addon AI API
- **Backend API** de la plataforma
- **Puerto**: 8080
- **Base de datos**: PostgreSQL (desde infraestructura)
- **Cache**: Redis
- **Autoscaling**: Configurado por ambiente

### 2. Addon AI Frontend
- **Frontend React** de la plataforma
- **Puerto**: 3000 (interno), 80 (servicio)
- **API URL**: Configurada por ambiente

### 3. Redis (Helm Chart Externo)
- **Cache y sesiones**
- **Despliegue**: Bitnami Helm Chart
- **Modo**: Standalone (dev), HA (prod)
- **Persistencia**: Deshabilitada en dev

## Configuración por Ambiente

### Development
- **Replicas**: 1
- **Resources**: Mínimos
- **Autoscaling**: Deshabilitado
- **Logging**: Debug
- **Domain**: `dev.addon-ai.com`

### Test
- **Replicas**: 1
- **Resources**: Mínimos
- **Autoscaling**: Deshabilitado
- **Features**: Test routes, mocked APIs
- **Domain**: `test.addon-ai.com`

### Staging
- **Replicas**: 2
- **Resources**: Medios
- **Autoscaling**: Habilitado (2-5)
- **Logging**: Info
- **Domain**: `staging.addon-ai.com`

### Production
- **Replicas**: 3+
- **Resources**: Altos
- **Autoscaling**: Habilitado (3-10)
- **Anti-affinity**: Habilitado
- **TLS**: Habilitado
- **Domain**: `addon-ai.com`

## Uso

```bash
# Desplegar API en dev
helm upgrade --install addon-ai-api ./charts/addon-ai-api \
  -f shared/app-deployment/helm-values/dev/addon-ai-api.yaml \
  -n addon-ai-dev

# Desplegar Frontend en dev
helm upgrade --install addon-ai-frontend ./charts/addon-ai-frontend \
  -f shared/app-deployment/helm-values/dev/addon-ai-frontend.yaml \
  -n addon-ai-dev

# Desplegar Redis en dev (Bitnami Chart)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install redis bitnami/redis \
  -f shared/app-deployment/helm-values/dev/redis.yaml \
  -n addon-ai-dev --create-namespace

# Desplegar en test
helm upgrade --install addon-ai-api ./charts/addon-ai-api \
  -f shared/app-deployment/helm-values/test/addon-ai-api.yaml \
  -n addon-ai-test
```

## Integración con Istio

Todos los valores incluyen configuración para:
- **VirtualService**: Routing HTTP
- **DestinationRule**: mTLS y load balancing
- **Gateway**: Configurado en módulo Istio

## Variables de Entorno

### API
- `NODE_ENV`: Ambiente de ejecución
- `DATABASE_URL`: Conexión a PostgreSQL (desde secret)
- `REDIS_URL`: Conexión a Redis
- `LOG_LEVEL`: Nivel de logging

### Frontend
- `REACT_APP_API_URL`: URL del API
- `REACT_APP_ENVIRONMENT`: Ambiente actual

## Secrets

Los secrets se crean separadamente:
```bash
kubectl create secret generic addon-ai-secrets \
  --from-literal=database-url="postgresql://..." \
  -n addon-ai-dev
```

## SSL/TLS Automático con Cert-Manager

### Configuración
Todos los ambientes están configurados para usar certificados SSL automáticos:

```bash
# 1. Instalar Cert-Manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# 2. Aplicar ClusterIssuer (Let's Encrypt)
kubectl apply -f shared/cluster-addons/security/cert-manager/cluster-issuer.yaml

# 3. Aplicar Certificate para dev
kubectl apply -f shared/cluster-addons/security/cert-manager/dev-certificate.yaml

# 4. Verificar certificado
kubectl get certificate -n istio-system
kubectl describe certificate dev-addon-ai-tls -n istio-system
```

### Dominios con SSL
- **Dev**: `https://dev.addon-ai.com` (Let's Encrypt Staging)
- **Test**: `https://test.addon-ai.com` (Let's Encrypt Staging)
- **Staging**: `https://staging.addon-ai.com` (Let's Encrypt Production)
- **Prod**: `https://addon-ai.com` (Let's Encrypt Production)

### Características
- ✅ **Certificados gratuitos** de Let's Encrypt
- ✅ **Renovación automática** cada 60 días
- ✅ **HTTP → HTTPS redirect** automático
- ✅ **Válidos en navegadores** (no self-signed)
- ✅ **Sin configuración manual** de certificados