# OCI Terraform Infrastructure

Infraestructura como código para Oracle Cloud Infrastructure (OCI).

## Estructura

```
oci/
├── modules/
│   ├── networking/    # VCN, Subnets, Gateways, Security Lists
│   ├── k8s-cluster/   # OKE Cluster, Node Pools (Flex Shapes)
│   └── database/      # MySQL HeatWave, HA Cluster
└── environments/
    ├── dev/           # Basic Cluster, Ampere A1 (ARM), Standalone MySQL
    └── prod/          # Enhanced Cluster, E4 Flex (AMD), HeatWave HA
```

## Ambientes

### Dev
- **OKE**: Basic Cluster (Free Tier)
- **Nodes**: VM.Standard.A1.Flex (Ampere ARM)
- **DB**: MySQL Standalone

### Prod
- **OKE**: Enhanced Cluster (SLA)
- **Nodes**: VM.Standard.E4.Flex (AMD)
- **DB**: MySQL HeatWave HA Cluster

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
