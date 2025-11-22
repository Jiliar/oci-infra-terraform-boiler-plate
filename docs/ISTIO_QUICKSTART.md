# Istio Service Mesh - Terraform Deployment Guide

## Overview

This guide explains how to deploy Istio Service Mesh using the Terraform module in each environment. Istio is deployed separately after the main OKE cluster infrastructure.

## Prerequisites

- OKE Cluster deployed via main Terraform configuration
- OCI CLI configured
- Terraform >= 1.5.0
- kubectl access to the cluster

## Directory Structure

```
environments/oci/
├── dev/istio/
├── test/istio/
├── staging/istio/
└── prod/istio/
```

Each environment has its own Istio configuration with environment-specific settings.

## Deployment Steps

### 1. Update Cluster ID (IMPORTANT)

**Before deploying Istio, you must update the cluster_id in terraform.tfvars to reference the current active OKE cluster.**

#### Option A: Using the Unified Script (Recommended)

```bash
# Update cluster_id automatically for any environment
./oci-terraform-manager.sh istio-update dev     # for dev
./oci-terraform-manager.sh istio-update test    # for test
./oci-terraform-manager.sh istio-update staging # for staging
./oci-terraform-manager.sh istio-update prod    # for prod
```

The script will:
- List all active OKE clusters
- Allow you to select the correct cluster if multiple exist
- Automatically update the `cluster_id` in `terraform.tfvars`
- Create a backup of the original file

#### Option B: Manual Update

```bash
# Get active clusters
oci ce cluster list --compartment-id "your-compartment-id" --query "data[?\"lifecycle-state\"=='ACTIVE'].{id:id,name:name}" --output table

# Copy the cluster ID and update terraform.tfvars
cd environments/oci/dev/istio
# Edit terraform.tfvars and update cluster_id = "new-cluster-ocid"
```

### 2. Navigate to Environment

```bash
cd environments/oci/dev/istio  # or test/staging/prod
```

### 3. Configure Variables

Edit `terraform.tfvars` with your environment-specific values:

```hcl
# OCI Authentication (same as main infrastructure)
tenancy_ocid   = "ocid1.tenancy.oc1..your-tenancy-id"
user_ocid      = "ocid1.user.oc1..your-user-id"
fingerprint    = "your-fingerprint"
private_key    = "your-private-key"
region         = "sa-bogota-1"

# Cluster ID from main infrastructure
cluster_id = "ocid1.cluster.oc1.sa-bogota-1.your-cluster-id"

# Istio Configuration
istio_version                    = "1.20.0"
enable_gateway                   = true
gateway_name                     = "addon-ai-dev-gateway"
gateway_namespace                = "default"
gateway_hosts                    = ["dev.addon-ai.com"]
enable_virtualservice            = true
virtualservice_name              = "addon-ai-dev-vs"
virtualservice_namespace         = "default"
virtualservice_hosts             = ["dev.addon-ai.com"]
virtualservice_destination_host  = "addon-ai-dev-service"
virtualservice_destination_port  = 80
enable_peer_authentication       = true
mtls_mode                        = "STRICT"

# TLS/SSL Configuration
enable_tls                       = true
enable_https_redirect            = true
tls_secret_name                  = "dev-addon-ai-tls"
```

### 4. Deploy Istio

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

## What Gets Deployed

The Terraform module deploys:

### Core Components
- **Istio Base** - CRDs and base configuration
- **Istiod** - Control plane (pilot, citadel, galley)
- **Istio Ingress Gateway** - LoadBalancer service for external traffic

### Networking Configuration
- **Gateway** - Defines ingress points for external traffic
- **VirtualService** - Routes traffic to backend services
- **PeerAuthentication** - Configures mTLS between services

### Features Enabled
- Automatic sidecar injection
- mTLS encryption between services
- Traffic management and routing
- Security policies
- Observability (metrics, traces, logs)

## Verification

### Check Istio Status

```bash
# Verify Istio pods
kubectl get pods -n istio-system

# Check gateway service
kubectl get svc -n istio-system istio-ingressgateway

# Verify gateway configuration
kubectl get gateway -n default

# Check virtual service
kubectl get virtualservice -n default
```

### Test Connectivity

```bash
# Get external IP
export INGRESS_HOST=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test HTTP access
curl -H "Host: dev.addon-ai.com" http://$INGRESS_HOST/

# Test HTTPS (if TLS enabled)
curl -H "Host: dev.addon-ai.com" https://$INGRESS_HOST/
```

## Environment-Specific Configurations

### Development
- Basic security (mTLS PERMISSIVE)
- Single replica components
- HTTP + HTTPS with self-signed certs

### Test
- Similar to dev with test domain
- Enhanced logging for debugging

### Staging
- Production-like security (mTLS STRICT)
- Multiple replicas for HA
- Valid SSL certificates

### Production
- Full security hardening
- High availability setup
- Production SSL certificates
- Advanced traffic policies

## Application Integration

### Enable Sidecar Injection

```bash
# Label namespace for automatic injection
kubectl label namespace default istio-injection=enabled

# Verify injection
kubectl get namespace -L istio-injection
```

### Deploy Application with Istio

```yaml
# app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ai-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: addon-ai-app
  template:
    metadata:
      labels:
        app: addon-ai-app
    spec:
      containers:
      - name: app
        image: your-app:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: addon-ai-dev-service
spec:
  selector:
    app: addon-ai-app
  ports:
  - port: 80
    targetPort: 8080
```

## Observability

### Access Dashboards

The module doesn't deploy observability addons by default. To add them:

```bash
# Install Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Install Prometheus
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml

# Install Grafana
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

# Access Kiali
kubectl port-forward -n istio-system svc/kiali 20001:20001
```

## Troubleshooting

### Common Issues

#### 1. Cluster Deleted Error

**Error**: `Cannot create kubeconfig because cluster ocid1.cluster.oc1... has been deleted`

**Solution**: The cluster_id in terraform.tfvars references a deleted cluster.

```bash
# Fix automatically
./oci-terraform-manager.sh istio-update dev

# Or manually update cluster_id in terraform.tfvars
```

#### 2. Istio Configuration Issues

```bash
# Check Istio configuration
istioctl analyze

# Verify proxy status
istioctl proxy-status

# Check sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Debug traffic routing
istioctl proxy-config route <pod-name> -n <namespace>
```

#### 3. Provider Authentication Issues

```bash
# Verify OCI CLI configuration
oci iam user get --user-id "your-user-ocid"

# Test cluster access
kubectl get nodes
```

### Logs

```bash
# Istiod logs
kubectl logs -n istio-system deployment/istiod

# Gateway logs
kubectl logs -n istio-system deployment/istio-ingressgateway

# Application sidecar logs
kubectl logs <pod-name> -c istio-proxy
```

## Cleanup

```bash
# Destroy Istio infrastructure
terraform destroy

# Remove injection labels
kubectl label namespace default istio-injection-
```

## Unified Management Script

Use the unified script for all Istio operations:

```bash
# Update cluster_id for Istio
./oci-terraform-manager.sh istio-update <env>

# Check infrastructure status
./oci-terraform-manager.sh status <env>

# Validate all modules
./oci-terraform-manager.sh validate

# Deploy main infrastructure first
./oci-terraform-manager.sh deploy <env>

# Then deploy Istio separately
cd environments/oci/<env>/istio
terraform init
terraform apply
```

## Module Configuration

The Istio module supports these key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `istio_version` | Istio version to deploy | `1.20.0` |
| `enable_gateway` | Create Istio Gateway | `true` |
| `gateway_hosts` | Hosts for the gateway | `["*"]` |
| `enable_tls` | Enable HTTPS/TLS | `false` |
| `mtls_mode` | mTLS mode (STRICT/PERMISSIVE) | `PERMISSIVE` |
| `enable_peer_authentication` | Enable mTLS between services | `true` |

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [OCI OKE + Istio](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengistioservicemesh.htm)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)