# Istio Quick Start Guide

## Instalación Rápida

### 1. Ejecutar Setup
```bash
./istio-setup.sh dev
```

### 2. Acceder a Dashboards
```bash
./dashboard-access.sh
```

## URLs de Acceso

| Dashboard | URL | Credenciales |
|-----------|-----|--------------|
| Grafana | http://localhost:3000 | admin/dev-grafana-password |
| Jaeger | http://localhost:16686 | Sin autenticación |
| Kiali | http://localhost:20001 | Sin autenticación |
| Prometheus | http://localhost:9090 | Sin autenticación |

## Verificación

### Estado de Pods
```bash
kubectl get pods -n istio-system
kubectl get pods -n monitoring
```

### Servicios
```bash
kubectl get svc -n istio-system
kubectl get svc -n monitoring
```

### LoadBalancer IP
```bash
kubectl get svc istio-ingressgateway -n istio-system
```

## Comandos Útiles

### Istio
```bash
# Verificar proxy status
istioctl proxy-status

# Analizar configuración
istioctl analyze

# Ver configuración de proxy
istioctl proxy-config cluster <pod-name>
```

### Troubleshooting
```bash
# Logs de istiod
kubectl logs -n istio-system deployment/istiod

# Logs de ingress gateway
kubectl logs -n istio-system deployment/istio-ingressgateway

# Describir pods con problemas
kubectl describe pod <pod-name> -n istio-system
```

## Cleanup
```bash
# Detener port-forwards
Ctrl+C en terminal de dashboard-access.sh

# Desinstalar Istio
istioctl uninstall --purge
kubectl delete namespace istio-system
```