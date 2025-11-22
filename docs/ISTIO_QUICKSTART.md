# Istio Service Mesh - Deployment Guide

## Prerequisites

- OKE Cluster deployed and running
- kubectl configured to access the cluster
- Helm 3.x installed

## Quick Start

### 1. Configure kubectl

```bash
# Get cluster kubeconfig
oci ce cluster create-kubeconfig --cluster-id <CLUSTER_OCID> --file ~/.kube/config --region sa-bogota-1

# Verify connection
kubectl get nodes
```

### 2. Install Istio

```bash
cd environments/oci/dev/istio

# Download and install Istio
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-*/bin:$PATH

# Install Istio base components
istioctl install --set values.defaultRevision=default -y

# Enable Istio injection for default namespace
kubectl label namespace default istio-injection=enabled
```

### 3. Deploy Istio Addons

```bash
# Install Kiali, Prometheus, Grafana, Jaeger
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

# Wait for deployments
kubectl rollout status deployment/kiali -n istio-system
```

### 4. Configure Gateway

```bash
# Apply Istio Gateway configuration
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: addon-ai-gateway
  namespace: default
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
EOF
```

### 5. Access Dashboards

```bash
# Kiali Dashboard
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Access: http://localhost:20001

# Grafana Dashboard  
kubectl port-forward -n istio-system svc/grafana 3000:3000
# Access: http://localhost:3000

# Jaeger Tracing
kubectl port-forward -n istio-system svc/jaeger 16686:16686
# Access: http://localhost:16686
```

## Verification

### Check Istio Status

```bash
# Verify Istio installation
istioctl version

# Check Istio components
kubectl get pods -n istio-system

# Verify proxy status
istioctl proxy-status
```

### Deploy Sample Application

```bash
# Deploy Bookinfo sample app
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo.yaml

# Create VirtualService
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/networking/bookinfo-gateway.yaml

# Get ingress IP
kubectl get svc istio-ingressgateway -n istio-system
```

## Configuration Files

### Gateway Configuration
```yaml
# gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: addon-ai-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "dev.addon-ai.com"
```

### VirtualService Example
```yaml
# virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: addon-ai-vs
spec:
  hosts:
  - "dev.addon-ai.com"
  gateways:
  - addon-ai-gateway
  http:
  - route:
    - destination:
        host: your-service
        port:
          number: 80
```

## Troubleshooting

### Common Issues

```bash
# Check Istio proxy logs
kubectl logs -l app=istio-proxy -c istio-proxy

# Verify sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Debug configuration
istioctl analyze

# Check proxy configuration
istioctl proxy-config cluster <POD_NAME>
```

### Cleanup

```bash
# Remove sample apps
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/bookinfo/platform/kube/bookinfo.yaml

# Uninstall Istio
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

## Production Considerations

- Configure proper resource limits
- Set up monitoring and alerting
- Implement security policies
- Configure traffic management rules
- Set up proper ingress with TLS

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [OKE + Istio Guide](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengistioservicemesh.htm)