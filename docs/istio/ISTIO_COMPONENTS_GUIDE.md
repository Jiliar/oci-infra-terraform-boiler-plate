# Guía de Componentes de Istio

## Descripción General
Componentes del service mesh Istio para clusters de Kubernetes en OCI a través de diferentes ambientes.

## Componentes

### Componentes Principales
- **Istiod**: Plano de control unificado
  - Pilot: Gestión de configuración y descubrimiento de servicios
  - Citadel: Gestión de certificados y políticas de seguridad
  - Galley: Validación y distribución de configuración
  - Recursos mínimos: 100m CPU, 128Mi RAM (dev/test)
  - Recursos producción: 500m CPU, 2Gi RAM con HPA

- **Istio Proxy**: Contenedores sidecar Envoy
  - Intercepta todo el tráfico de red del pod
  - Implementa políticas de seguridad y enrutamiento
  - Recolecta métricas y trazas
  - Configuración automática vía inyección de sidecar

- **Istio Gateway**: Gestión de tráfico de entrada/salida
  - Punto de entrada para tráfico externo
  - Configuración de TLS y certificados
  - Balanceador de carga integrado con OCI
  - Soporte para múltiples protocolos (HTTP, HTTPS, TCP)

### Gestión de Tráfico
- **VirtualService**: Reglas de enrutamiento y división de tráfico
  - Enrutamiento basado en headers, URI, métodos HTTP
  - División de tráfico para despliegues canary
  - Inyección de fallas para pruebas de resiliencia
  - Timeouts y reintentos configurables

- **DestinationRule**: Políticas de balanceador de carga y circuit breaker
  - Algoritmos de balanceo: round-robin, least-conn, random
  - Circuit breaker con umbrales configurables
  - Configuración de pools de conexiones
  - Detección de outliers y health checks

- **Gateway**: Puntos de entrada de tráfico externo
  - Configuración de puertos y protocolos
  - Gestión de certificados TLS/SSL
  - Integración con DNS y dominios
  - Políticas de seguridad en el borde

- **ServiceEntry**: Registro de servicios externos
  - Permite acceso a servicios fuera del mesh
  - Configuración de endpoints externos
  - Políticas de seguridad para servicios externos
  - Métricas y observabilidad de tráfico externo

### Seguridad
- **PeerAuthentication**: Configuración de mTLS
  - Modo STRICT: mTLS obligatorio para toda comunicación
  - Modo PERMISSIVE: permite tráfico con y sin mTLS
  - Configuración por namespace o workload específico
  - Rotación automática de certificados

- **AuthorizationPolicy**: Políticas de control de acceso
  - Control basado en identidades de servicio
  - Reglas por método HTTP, path, headers
  - Denegación y permitir explícito
  - Integración con sistemas de identidad externos

- **RequestAuthentication**: Validación de JWT
  - Validación de tokens JWT en requests
  - Configuración de issuers y audiences
  - Extracción de claims para autorización
  - Integración con proveedores OIDC

### Observabilidad
- **Telemetry**: Configuración de métricas, logs y trazas
  - Métricas personalizadas de Prometheus
  - Configuración de sampling de trazas
  - Logs estructurados con contexto de mesh
  - Dashboards automáticos en Grafana

- **EnvoyFilter**: Configuración personalizada del proxy Envoy
  - Filtros HTTP personalizados
  - Configuración de listeners y clusters
  - Extensiones de Envoy (WASM, Lua)
  - Optimizaciones de rendimiento específicas

## Configuración por Ambiente

### Dev/Test
```yaml
# Configuración básica de Istio
components:
  pilot:
    k8s:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi
      env:
        PILOT_TRACE_SAMPLING: 100.0  # 100% sampling para desarrollo
        PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION: true
  
  ingressGateways:
  - name: istio-ingressgateway
    k8s:
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 128Mi
      service:
        type: LoadBalancer
        annotations:
          oci.oraclecloud.com/load-balancer-type: "lb"
```

### Staging/Prod
```yaml
# Configuración de producción de Istio
components:
  pilot:
    k8s:
      resources:
        requests:
          cpu: 500m
          memory: 2Gi
        limits:
          cpu: 1000m
          memory: 4Gi
      hpaSpec:
        minReplicas: 2
        maxReplicas: 5
        metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 80
      env:
        PILOT_TRACE_SAMPLING: 1.0  # 1% sampling para producción
        PILOT_ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY: true
  
  ingressGateways:
  - name: istio-ingressgateway
    k8s:
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
      hpaSpec:
        minReplicas: 2
        maxReplicas: 10
      service:
        type: LoadBalancer
        annotations:
          oci.oraclecloud.com/load-balancer-type: "nlb"
          oci.oraclecloud.com/load-balancer-shape: "flexible"
          oci.oraclecloud.com/load-balancer-shape-flex-min: "10"
          oci.oraclecloud.com/load-balancer-shape-flex-max: "100"
```

## Instalación

### Valores de Helm
```yaml
global:
  meshID: oci-mesh
  network: oci-network
  defaultPodDisruptionBudget:
    enabled: true
  proxy:
    resources:
      requests:
        cpu: 10m
        memory: 40Mi
      limits:
        cpu: 100m
        memory: 128Mi
    logLevel: warning
    componentLogLevel: "misc:error"
  
pilot:
  traceSampling: 1.0
  env:
    EXTERNAL_ISTIOD: false
    PILOT_SKIP_VALIDATE_TRUST_DOMAIN: true
  
gateways:
  istio-ingressgateway:
    type: LoadBalancer
    ports:
    - port: 15021
      targetPort: 15021
      name: status-port
      protocol: TCP
    - port: 80
      targetPort: 8080
      name: http2
      protocol: TCP
    - port: 443
      targetPort: 8443
      name: https
      protocol: TCP
    secretVolumes:
    - name: ingressgateway-certs
      secretName: istio-ingressgateway-certs
      mountPath: /etc/istio/ingressgateway-certs
    - name: ingressgateway-ca-certs
      secretName: istio-ingressgateway-ca-certs
      mountPath: /etc/istio/ingressgateway-ca-certs
    
telemetry:
  v2:
    enabled: true
    prometheus:
      configOverride:
        metric_relabeling_configs:
        - source_labels: [__name__]
          regex: 'istio_.*'
          target_label: __tmp_istio_metric
        - source_labels: [__name__]
          regex: 'envoy_.*'
          target_label: __tmp_envoy_metric
      service:
        annotations:
          prometheus.io/scrape: "true"
          prometheus.io/port: "15090"
          prometheus.io/path: "/stats/prometheus"
```

### Configuración de Gateway
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: oci-gateway
  namespace: istio-system
  labels:
    app: istio-gateway
    environment: dev
spec:
  selector:
    istio: ingressgateway
  servers:
  # Puerto HTTP con redirección automática a HTTPS
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
    tls:
      httpsRedirect: true
  
  # Puerto HTTPS con TLS
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: tls-secret
      minProtocolVersion: TLSV1_2
      maxProtocolVersion: TLSV1_3
      cipherSuites:
      - ECDHE-RSA-AES256-GCM-SHA384
      - ECDHE-RSA-AES128-GCM-SHA256
    hosts:
    - "api.example.com"
    - "app.example.com"
  
  # Puerto adicional para métricas (solo interno)
  - port:
      number: 15090
      name: http-monitoring
      protocol: HTTP
    hosts:
    - "monitoring.internal"
---
# VirtualService para enrutamiento
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: oci-virtualservice
  namespace: istio-system
spec:
  hosts:
  - "api.example.com"
  - "app.example.com"
  gateways:
  - oci-gateway
  http:
  - match:
    - uri:
        prefix: "/api/"
    route:
    - destination:
        host: backend-service
        port:
          number: 8080
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
  - match:
    - uri:
        prefix: "/"
    route:
    - destination:
        host: frontend-service
        port:
          number: 3000
```

## Políticas de Seguridad

### mTLS (Mutual TLS)
```yaml
# Política global de mTLS estricto
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
---
# Política específica para namespace de desarrollo (permisivo)
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: dev-permissive
  namespace: development
spec:
  mtls:
    mode: PERMISSIVE
---
# Política para servicio específico con puerto personalizado
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: database-mtls
  namespace: production
spec:
  selector:
    matchLabels:
      app: postgresql
  mtls:
    mode: STRICT
  portLevelMtls:
    5432:
      mode: DISABLE  # Puerto de base de datos sin mTLS
```

### Autorización
```yaml
# Política de autorización para frontend
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: production
spec:
  selector:
    matchLabels:
      app: frontend
  rules:
  # Permitir acceso desde backend específico
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/backend"]
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/*"]
  # Permitir acceso desde ingress gateway
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/health", "/ready"]
---
# Política de denegación por defecto
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  selector:
    matchLabels:
      app: sensitive-service
  # Sin reglas = denegar todo por defecto
---
# Política basada en JWT
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-auth
  namespace: production
spec:
  selector:
    matchLabels:
      app: api-service
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
    when:
    - key: request.auth.claims[role]
      values: ["admin", "user"]
    - key: request.auth.claims[iss]
      values: ["https://auth.example.com"]
```

## Integración de Monitoreo

### Prometheus
- **Recolección de métricas**: Automática desde proxies Envoy
  - Métricas de latencia, throughput, errores (RED metrics)
  - Métricas de recursos (CPU, memoria, conexiones)
  - Métricas personalizadas de aplicación
  - Configuración de scraping cada 15 segundos

- **Dashboards personalizados**: Para observabilidad del service mesh
  - Dashboard de servicios con SLI/SLO
  - Dashboard de rendimiento de workloads
  - Dashboard de seguridad y mTLS
  - Dashboard de topología de red

- **Reglas de alerta**: Para salud de servicios
  - Alta tasa de errores (>5% por 5 minutos)
  - Latencia elevada (p99 >1s por 10 minutos)
  - Servicios no disponibles
  - Certificados próximos a expirar

- **Acceso**: http://localhost:9090
  - Interfaz web para consultas PromQL
  - Explorador de métricas
  - Visualización de targets y alertas

### Dashboards de Grafana
- **Istio Service Dashboard**:
  - Métricas por servicio (request rate, latency, success rate)
  - Gráficos de tendencias temporales
  - Comparación entre versiones de servicio
  - Alertas visuales por umbrales

- **Istio Workload Dashboard**:
  - Métricas por workload/deployment
  - Uso de recursos por pod
  - Distribución de tráfico
  - Health checks y readiness

- **Istio Performance Dashboard**:
  - Métricas de rendimiento de Envoy
  - Latencia de proxy vs aplicación
  - Throughput y conexiones concurrentes
  - Overhead del service mesh

- **Kubernetes Cluster Monitoring**:
  - Estado de nodos y pods
  - Uso de recursos del cluster
  - Eventos y logs del sistema
  - Capacidad y escalamiento

- **Acceso**: http://localhost:3000 (admin/dev-grafana-password)
  - Dashboards interactivos
  - Alerting integrado
  - Anotaciones y variables

### Jaeger Tracing
- **Configuración de trazado distribuido**:
  - Instrumentación automática vía Envoy
  - Propagación de contexto entre servicios
  - Sampling configurable por ambiente
  - Retención de trazas por 7 días

- **Tasas de sampling por ambiente**:
  - Desarrollo: 100% (debugging completo)
  - Test: 50% (validación de flujos)
  - Staging: 10% (pruebas de carga)
  - Producción: 1% (overhead mínimo)

- **Despliegue all-in-one**: Con almacenamiento en memoria
  - Collector, query, y UI en un solo pod
  - Configuración simplificada para desarrollo
  - Escalable a despliegue distribuido

- **Acceso**: http://localhost:16686
  - Búsqueda de trazas por servicio/operación
  - Análisis de latencia y cuellos de botella
  - Visualización de dependencias
  - Comparación de trazas

### Kiali Service Mesh
- **Visualización de topología de servicios**:
  - Grafo interactivo de servicios
  - Relaciones y dependencias
  - Estado de salud visual
  - Filtros por namespace/aplicación

- **Análisis de flujo de tráfico**:
  - Métricas en tiempo real
  - Patrones de comunicación
  - Detección de anomalías
  - Análisis de seguridad mTLS

- **Validación de configuración**:
  - Validación de YAML de Istio
  - Detección de configuraciones conflictivas
  - Sugerencias de mejores prácticas
  - Wizard para configuración común

- **Acceso**: http://localhost:20001 (anonymous)
  - Interfaz web intuitiva
  - Navegación por namespaces
  - Integración con Grafana y Jaeger
  - Exportación de configuraciones

## Mejores Prácticas

### Gestión de Recursos
- **Establecer límites apropiados de CPU/memoria**:
  - Control plane: mínimo 500m CPU, 2Gi RAM en producción
  - Sidecars: 10m CPU, 40Mi RAM por defecto
  - Gateways: escalar según tráfico esperado
  - Monitorear uso real y ajustar límites

- **Configurar HPA para componentes del plano de control**:
  - Istiod: escalar basado en CPU (80% umbral)
  - Ingress Gateway: escalar basado en conexiones
  - Métricas personalizadas para scaling avanzado
  - Configurar PodDisruptionBudgets

- **Usar afinidad de nodos para componentes críticos**:
  - Dedicar nodos para plano de control
  - Separar workloads por criticidad
  - Usar taints y tolerations
  - Configurar anti-afinidad para HA

### Seguridad
- **Habilitar mTLS por defecto**:
  - Modo STRICT en producción
  - Modo PERMISSIVE durante migración
  - Validar certificados regularmente
  - Monitorear conexiones no seguras

- **Implementar políticas de autorización de menor privilegio**:
  - Denegar por defecto, permitir explícitamente
  - Usar service accounts específicos
  - Validar identidades con JWT
  - Auditar accesos regularmente

- **Rotación regular de certificados**:
  - Rotación automática cada 90 días
  - Monitorear expiración de certificados
  - Backup de certificados críticos
  - Procedimientos de emergencia

### Rendimiento
- **Ajustar configuraciones del proxy Envoy**:
  - Pools de conexiones optimizados
  - Timeouts apropiados por servicio
  - Circuit breakers configurados
  - Compresión habilitada cuando sea apropiado

- **Configurar sampling de trazas apropiado**:
  - 1% en producción para overhead mínimo
  - 100% en desarrollo para debugging
  - Sampling adaptativo basado en carga
  - Retención optimizada por ambiente

- **Monitorear uso de recursos y escalamiento**:
  - Alertas por uso elevado de CPU/memoria
  - Métricas de latencia y throughput
  - Análisis de tendencias de crecimiento
  - Capacity planning proactivo

## Solución de Problemas

### Problemas Comunes
1. **Fallas en inyección de sidecar**:
   - Verificar etiquetas de namespace: `istio-injection=enabled`
   - Comprobar webhook de mutación activo
   - Validar políticas de admisión
   - Revisar logs del webhook: `kubectl logs -n istio-system deployment/istiod`

2. **Problemas de certificados**:
   - Verificar configuración de CA raíz
   - Comprobar rotación automática de certificados
   - Validar trust domain configuration
   - Revisar fecha de expiración: `istioctl proxy-config secret <pod> -o json`

3. **Enrutamiento de tráfico**:
   - Validar reglas de VirtualService
   - Comprobar coincidencia de hosts y gateways
   - Verificar orden de precedencia de reglas
   - Analizar configuración: `istioctl analyze`

4. **Rendimiento**:
   - Verificar recursos del proxy Envoy
   - Comprobar configuración de pools de conexión
   - Analizar métricas de latencia
   - Revisar configuración de circuit breakers

### Comandos de Debug
```bash
# Verificar estado de Istio
istioctl proxy-status
istioctl version
kubectl get pods -n istio-system

# Analizar configuración completa
istioctl analyze --all-namespaces
istioctl analyze -n <namespace>

# Ver configuración del proxy
istioctl proxy-config cluster <pod-name> -n <namespace>
istioctl proxy-config listener <pod-name> -n <namespace>
istioctl proxy-config route <pod-name> -n <namespace>
istioctl proxy-config endpoint <pod-name> -n <namespace>

# Verificar certificados y secretos
istioctl proxy-config secret <pod-name> -n <namespace>
istioctl authn tls-check <pod-name>.<namespace>.svc.cluster.local

# Debug de políticas de autorización
istioctl experimental authz check <pod-name> -n <namespace>

# Logs detallados
kubectl logs <pod-name> -c istio-proxy -n <namespace>
kubectl logs -n istio-system deployment/istiod

# Configuración de debug en tiempo real
istioctl proxy-config log <pod-name> --level debug
istioctl proxy-config log <pod-name> --level info  # volver a normal
```

## Acceso a Dashboards

### Acceso Rápido
```bash
# Iniciar todos los dashboards
./dashboard-access.sh

# Verificar que todos los servicios estén ejecutándose
kubectl get pods -n istio-system
kubectl get pods -n monitoring

# Verificar servicios disponibles
kubectl get svc -n istio-system
kubectl get svc -n monitoring
```

### Port-Forward Manual
```bash
# Grafana - Dashboard principal de métricas
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Acceso: http://localhost:3000
# Credenciales: admin/dev-grafana-password

# Jaeger - Trazado distribuido
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686
# Acceso: http://localhost:16686
# Sin autenticación requerida

# Kiali - Topología del service mesh
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Acceso: http://localhost:20001
# Autenticación: anonymous (configurado)

# Prometheus - Métricas y alertas
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Acceso: http://localhost:9090
# Interfaz de consultas PromQL

# Alertmanager - Gestión de alertas
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Acceso: http://localhost:9093
```

### URLs de Dashboard
- **Grafana**: http://localhost:3000
  - Usuario: admin
  - Contraseña: dev-grafana-password
  - Dashboards: Istio, Kubernetes, aplicaciones

- **Jaeger**: http://localhost:16686
  - Trazado distribuido
  - Análisis de latencia
  - Búsqueda por servicio/operación

- **Kiali**: http://localhost:20001
  - Topología del service mesh
  - Análisis de tráfico en tiempo real
  - Validación de configuración

- **Prometheus**: http://localhost:9090
  - Consultas de métricas
  - Explorador de targets
  - Estado de alertas

### Dashboards Clave en Grafana
- **Istio Service Dashboard**:
  - ID: 7639 (importado automáticamente)
  - Métricas por servicio y namespace
  - Request rate, latency, success rate

- **Istio Workload Dashboard**:
  - ID: 7630 (importado automáticamente)
  - Métricas por workload/deployment
  - Uso de recursos y rendimiento

- **Istio Performance Dashboard**:
  - ID: 11829 (importado automáticamente)
  - Rendimiento del control plane
  - Métricas de Envoy proxy

- **Kubernetes Cluster Monitoring**:
  - ID: 315 (importado automáticamente)
  - Estado general del cluster
  - Recursos y capacidad