# Guía de Inicio Rápido de Istio

## Instalación Rápida

### 1. Ejecutar Setup
```bash
# Instalar Istio en ambiente de desarrollo
./istio-setup.sh dev

# Verificar instalación exitosa
kubectl get pods -n istio-system
kubectl get svc -n istio-system

# Verificar que istiod esté ejecutándose
kubectl get deployment -n istio-system istiod
```

### 2. Acceder a Dashboards
```bash
# Iniciar todos los dashboards de monitoreo
./dashboard-access.sh

# El script configurará port-forwarding para:
# - Grafana (métricas y dashboards)
# - Jaeger (trazado distribuido)
# - Kiali (topología del mesh)
# - Prometheus (métricas base)
```

## URLs de Acceso

| Dashboard | URL | Credenciales | Propósito |
|-----------|-----|--------------|----------|
| Grafana | http://localhost:3000 | admin/dev-grafana-password | Dashboards y métricas |
| Jaeger | http://localhost:16686 | Sin autenticación | Trazado distribuido |
| Kiali | http://localhost:20001 | Sin autenticación | Topología del service mesh |
| Prometheus | http://localhost:9090 | Sin autenticación | Métricas y alertas |

## Verificación de Instalación

### Estado de Pods
```bash
# Verificar pods del sistema Istio
kubectl get pods -n istio-system
# Debe mostrar: istiod, istio-ingressgateway en estado Running

# Verificar pods de monitoreo
kubectl get pods -n monitoring
# Debe mostrar: prometheus, grafana, jaeger en estado Running

# Verificar logs si hay problemas
kubectl logs -n istio-system deployment/istiod
kubectl logs -n istio-system deployment/istio-ingressgateway
```

### Servicios y Endpoints
```bash
# Servicios de Istio
kubectl get svc -n istio-system
# Verificar que istio-ingressgateway tenga EXTERNAL-IP asignada

# Servicios de monitoreo
kubectl get svc -n monitoring
# Verificar servicios de prometheus, grafana, jaeger

# Verificar endpoints disponibles
kubectl get endpoints -n istio-system
kubectl get endpoints -n monitoring
```

### LoadBalancer y Conectividad
```bash
# Obtener IP externa del LoadBalancer
kubectl get svc istio-ingressgateway -n istio-system
# Anotar la EXTERNAL-IP para configuración de DNS

# Verificar puertos expuestos
kubectl get svc istio-ingressgateway -n istio-system -o yaml

# Probar conectividad (reemplazar <EXTERNAL-IP>)
curl -I http://<EXTERNAL-IP>
curl -I https://<EXTERNAL-IP> -k
```

## Comandos Útiles

### Comandos de Istio
```bash
# Verificar estado de todos los proxies
istioctl proxy-status
# Muestra qué pods tienen sidecar y su estado de sincronización

# Analizar configuración completa del mesh
istioctl analyze
# Detecta problemas de configuración y sugiere soluciones

# Ver configuración detallada del proxy
istioctl proxy-config cluster <pod-name> -n <namespace>
istioctl proxy-config listener <pod-name> -n <namespace>
istioctl proxy-config route <pod-name> -n <namespace>

# Verificar versión de Istio
istioctl version
# Debe mostrar versión del cliente y del control plane

# Verificar configuración de mTLS
istioctl authn tls-check <service>.<namespace>.svc.cluster.local
```

### Comandos de Kubernetes
```bash
# Verificar inyección de sidecar en namespace
kubectl get namespace -L istio-injection

# Habilitar inyección automática en namespace
kubectl label namespace <namespace> istio-injection=enabled

# Verificar recursos de Istio
kubectl get virtualservices,destinationrules,gateways -A

# Ver configuración de Istio
kubectl get istiooperator -n istio-system -o yaml
```

### Solución de Problemas
```bash
# Logs del plano de control (istiod)
kubectl logs -n istio-system deployment/istiod -f
# Usar -f para seguimiento en tiempo real

# Logs del ingress gateway
kubectl logs -n istio-system deployment/istio-ingressgateway -f
# Verificar errores de enrutamiento y TLS

# Logs del sidecar proxy en un pod específico
kubectl logs <pod-name> -c istio-proxy -n <namespace>
# Revisar errores de conectividad y políticas

# Describir recursos con problemas
kubectl describe pod <pod-name> -n istio-system
kubectl describe svc istio-ingressgateway -n istio-system

# Verificar eventos del cluster
kubectl get events -n istio-system --sort-by='.lastTimestamp'
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Debug de configuración de red
kubectl exec -it <pod-name> -c istio-proxy -n <namespace> -- netstat -tlnp
kubectl exec -it <pod-name> -c istio-proxy -n <namespace> -- ss -tlnp
```

### Problemas Comunes y Soluciones
```bash
# Problema: Sidecar no se inyecta
# Solución: Verificar etiqueta del namespace
kubectl label namespace <namespace> istio-injection=enabled

# Problema: Certificados TLS
# Solución: Verificar secretos y configuración
kubectl get secrets -n istio-system
istioctl proxy-config secret <pod-name> -n <namespace>

# Problema: Tráfico no enruta correctamente
# Solución: Verificar VirtualService y Gateway
kubectl get virtualservice,gateway -A
istioctl analyze -n <namespace>

# Problema: Alta latencia
# Solución: Verificar recursos y configuración
kubectl top pods -n istio-system
istioctl proxy-config cluster <pod-name> -n <namespace>
```

## Limpieza y Desinstalación

### Detener Dashboards
```bash
# Detener port-forwards activos
# Presionar Ctrl+C en la terminal donde se ejecutó dashboard-access.sh

# O matar procesos específicos
pkill -f "kubectl port-forward.*grafana"
pkill -f "kubectl port-forward.*jaeger"
pkill -f "kubectl port-forward.*kiali"
pkill -f "kubectl port-forward.*prometheus"

# Verificar que no hay port-forwards activos
ps aux | grep "kubectl port-forward"
```

### Desinstalar Istio Completamente
```bash
# Desinstalar Istio (mantiene CRDs)
istioctl uninstall

# Desinstalar completamente (elimina todo)
istioctl uninstall --purge

# Eliminar namespace de Istio
kubectl delete namespace istio-system

# Eliminar etiquetas de inyección de namespaces
kubectl label namespace <namespace> istio-injection-

# Verificar que no quedan recursos
kubectl get crd | grep istio
kubectl get all -n istio-system
```

### Desinstalar Monitoreo (Opcional)
```bash
# Si se instaló monitoreo por separado
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
helm uninstall jaeger -n monitoring

# Eliminar namespace de monitoreo
kubectl delete namespace monitoring

# Eliminar PVCs si existen
kubectl get pvc -A | grep -E "prometheus|grafana"
kubectl delete pvc <pvc-name> -n monitoring
```

### Verificación de Limpieza
```bash
# Verificar que Istio fue removido completamente
kubectl get pods -A | grep istio
kubectl get svc -A | grep istio
kubectl get crd | grep istio

# Verificar que no hay sidecars residuales
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}' | grep istio-proxy

# Verificar recursos de red
kubectl get networkpolicies -A
kubectl get ingress -A
```