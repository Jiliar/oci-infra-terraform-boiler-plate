# Istio Components Guide

## Overview
Istio service mesh components for OCI Kubernetes clusters across environments.

## Components

### Core Components
- **Istiod**: Control plane (pilot, citadel, galley)
- **Istio Proxy**: Envoy sidecar containers
- **Istio Gateway**: Ingress/egress traffic management

### Traffic Management
- **VirtualService**: Route rules and traffic splitting
- **DestinationRule**: Load balancing and circuit breaker policies
- **Gateway**: External traffic entry points
- **ServiceEntry**: External service registration

### Security
- **PeerAuthentication**: mTLS configuration
- **AuthorizationPolicy**: Access control policies
- **RequestAuthentication**: JWT validation

### Observability
- **Telemetry**: Metrics, logs, traces configuration
- **EnvoyFilter**: Custom Envoy proxy configuration

## Environment Configuration

### Dev/Test
```yaml
# Basic Istio setup
components:
  pilot:
    k8s:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
```

### Staging/Prod
```yaml
# Production Istio setup
components:
  pilot:
    k8s:
      resources:
        requests:
          cpu: 500m
          memory: 2Gi
      hpaSpec:
        minReplicas: 2
```

## Installation

### Helm Values
```yaml
global:
  meshID: oci-mesh
  network: oci-network
  
pilot:
  traceSampling: 1.0
  
gateways:
  istio-ingressgateway:
    type: LoadBalancer
    
telemetry:
  v2:
    prometheus:
      configOverride:
        metric_relabeling_configs:
        - source_labels: [__name__]
          regex: 'istio_.*'
          target_label: __tmp_istio_metric
```

### Gateway Configuration
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: oci-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: tls-secret
    hosts:
    - "*"
```

## Security Policies

### mTLS
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
```

### Authorization
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
spec:
  selector:
    matchLabels:
      app: frontend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/backend"]
```

## Monitoring Integration

### Prometheus
- Metrics collection from Envoy proxies
- Custom dashboards for service mesh observability
- Alert rules for service health
- Access: http://localhost:9090

### Grafana Dashboards
- Istio Service Dashboard
- Istio Workload Dashboard
- Istio Performance Dashboard
- Kubernetes Cluster Monitoring
- Access: http://localhost:3000 (admin/dev-grafana-password)

### Jaeger Tracing
- Distributed tracing configuration
- Trace sampling rates per environment
- All-in-one deployment with memory storage
- Access: http://localhost:16686

### Kiali Service Mesh
- Service topology visualization
- Traffic flow analysis
- Configuration validation
- Access: http://localhost:20001 (anonymous)

## Best Practices

### Resource Management
- Set appropriate CPU/memory limits
- Configure HPA for control plane components
- Use node affinity for critical components

### Security
- Enable mTLS by default
- Implement least-privilege authorization policies
- Regular certificate rotation

### Performance
- Tune Envoy proxy settings
- Configure appropriate trace sampling
- Monitor resource usage and scaling

## Troubleshooting

### Common Issues
1. **Sidecar injection failures**: Check namespace labels
2. **Certificate issues**: Verify CA configuration
3. **Traffic routing**: Validate VirtualService rules
4. **Performance**: Check Envoy proxy resources

### Debug Commands
```bash
# Check Istio status
istioctl proxy-status

# Analyze configuration
istioctl analyze

# View proxy configuration
istioctl proxy-config cluster <pod-name>

# Check certificates
istioctl proxy-config secret <pod-name>
```

## Dashboard Access

### Quick Access
```bash
# Start all dashboards
./dashboard-access.sh
```

### Manual Port-Forward
```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Jaeger
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686

# Kiali
kubectl port-forward -n istio-system svc/kiali 20001:20001

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### Dashboard URLs
- **Grafana**: http://localhost:3000 (admin/dev-grafana-password)
- **Jaeger**: http://localhost:16686 (tracing)
- **Kiali**: http://localhost:20001 (service mesh topology)
- **Prometheus**: http://localhost:9090 (metrics)

### Key Dashboards in Grafana
- Istio Service Dashboard
- Istio Workload Dashboard
- Istio Performance Dashboard
- Kubernetes Cluster Monitoring