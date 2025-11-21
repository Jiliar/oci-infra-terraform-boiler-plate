# OCI Terraform Infrastructure

Infraestructura como código para Oracle Cloud Infrastructure (OCI).

## Estructura

```
oci/
├── modules/
│   ├── networking/    # VCN, Subnets, Gateways, Security Lists
│   ├── k8s-cluster/   # OKE Cluster, Node Pools
│   ├── database/      # PostgreSQL Database
│   ├── istio/         # Service Mesh
│   ├── load-balancer/ # Load Balancer
│   ├── dns/           # DNS Zones
│   ├── vault/         # Secrets Management
│   ├── iam/           # IAM Policies
│   ├── waf/           # Web Application Firewall
│   ├── monitoring/    # Monitoring & Alerts
│   └── ocir/          # Container Registry
└── environments/
    ├── bootstrap/     # Terraform State Bucket
    ├── dev/           # Development (10.0.0.0/16)
    ├── test/          # Testing (10.1.0.0/16)
    ├── staging/       # Staging (10.2.0.0/16)
    └── prod/          # Production (10.3.0.0/16)
```

## Ambientes

### Dev (10.0.0.0/16)
- **OKE**: Basic Cluster (Free Tier)
- **Nodes**: VM.Standard3.Flex (1 vCPU, 16GB)
- **DB**: PostgreSQL Standalone (Free Tier)
- **Endpoint**: Público
- **Istio**: ✅

### Test (10.1.0.0/16)
- **OKE**: Basic Cluster
- **Nodes**: VM.Standard3.Flex (1 vCPU, 16GB)
- **DB**: PostgreSQL Standalone (Free Tier)
- **Endpoint**: Público
- **Istio**: ✅

### Staging (10.2.0.0/16)
- **OKE**: Basic Cluster
- **Nodes**: VM.Standard.E4.Flex (1 vCPU, 8GB, 2 nodes)
- **DB**: PostgreSQL (1 CPU, 1TB)
- **Endpoint**: Privado
- **WAF**: ✅
- **Istio**: ✅

### Prod (10.3.0.0/16)
- **OKE**: Enhanced Cluster (SLA)
- **Nodes**: VM.Standard.E4.Flex (2 vCPU, 16GB, 3 nodes)
- **DB**: PostgreSQL HA (2 CPU, 2TB)
- **Endpoint**: Privado
- **WAF**: ✅
- **Monitoring**: ✅
- **Istio**: ✅

## Uso

```bash
cd environments/dev
terraform init
terraform apply
```

## Requisitos
- OCI CLI configurado
- Terraform >= 1.5.0
- API Key configurada en ~/.oci/config
