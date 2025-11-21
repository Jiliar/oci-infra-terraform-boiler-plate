# OCI Terraform Infrastructure - Deployment Guide

## Problemas Conocidos y Soluciones

### Node Pool Creation Issues

**Problema**: Al crear node pools con Terraform se experimentan fallas de compatibilidad entre shapes e imágenes.

**Solución Recomendada**: Crear los node pools manualmente desde el Portal Cloud de OCI.

#### Pasos para crear Node Pool manualmente:

1. **Acceder al Portal Cloud OCI**
   - Ir a Developer Services > Kubernetes Clusters (OKE)
   - Seleccionar el cluster `addon-ai-dev-oke`

2. **Crear Node Pool**
   - Click en "Node Pools" en el menú lateral
   - Click en "Add Node Pool"

3. **Configuración del Node Pool**:
   ```
   Name: addon-ai-dev-pool
   Shape: VM.Standard3.Flex
   OCPUs: 1
   Memory: 16 GB
   Node Count: 1
   Kubernetes Version: v1.34.1
   Availability Domain: WBkQ:SA-BOGOTA-1-AD-1
   Subnet: addon-ai-dev-nodes
   ```

4. **Configuración de Imagen**:
   - Usar imagen compatible con VM.Standard3.Flex
   - Seleccionar la imagen Oracle Linux más reciente disponible

#### Comando OCI CLI (Alternativo):

```bash
# Obtener IDs necesarios
CLUSTER_ID=$(oci ce cluster list --compartment-id ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq --name "addon-ai-dev-oke" --query 'data[0].id' --raw-output)

SUBNET_ID=$(oci network subnet list --compartment-id ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq --display-name "addon-ai-dev-nodes" --query 'data[0].id' --raw-output)

# Crear Node Pool
oci ce node-pool create \
  --cluster-id $CLUSTER_ID \
  --compartment-id ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq \
  --name "addon-ai-dev-pool" \
  --node-shape "VM.Standard3.Flex" \
  --kubernetes-version "v1.34.1" \
  --node-shape-config '{"ocpus": 1, "memoryInGBs": 16}' \
  --node-config-details '{"size": 1, "placementConfigs": [{"availabilityDomain": "WBkQ:SA-BOGOTA-1-AD-1", "subnetId": "'$SUBNET_ID'"}]}' \
  --node-source-details '{"sourceType": "IMAGE", "imageId": "ocid1.image.oc1.sa-bogota-1.aaaaaaaalcrfyhysejbsevr32jppcn6vyicrl53f6zofplpieffqvstxluuq"}'
```

### Terraform Deployment

#### Crear solo el cluster (sin node pools):

```bash
cd environments/oci/dev
terraform init
terraform apply -target=module.k8s_cluster.oci_containerengine_cluster.oke
```

#### Importar Node Pool creado manualmente:

```bash
# Obtener el ID del node pool creado
NODE_POOL_ID=$(oci ce node-pool list --compartment-id ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq --query 'data[0].id' --raw-output)

# Importar a Terraform
terraform import module.k8s_cluster.oci_containerengine_node_pool.pools[\"default\"] $NODE_POOL_ID
```

## Configuraciones por Región

### sa-bogota-1 (Colombia)
- **Availability Domain**: `WBkQ:SA-BOGOTA-1-AD-1`
- **Shapes Disponibles**: VM.Standard3.Flex, VM.Standard.A1.Flex
- **Imágenes Recomendadas**: Oracle Linux 9.6 más reciente

### us-ashburn-1 (Estados Unidos)
- **Availability Domain**: `Uocm:US-ASHBURN-AD-1`
- **Shapes Disponibles**: VM.Standard.E4.Flex, VM.Standard.E5.Flex, VM.Standard.A1.Flex

## Troubleshooting

### Error: "Node shape and image are not compatible"
- **Causa**: Incompatibilidad entre shape (AMD/ARM) e imagen
- **Solución**: Usar Portal Cloud para selección automática de imagen compatible

### Error: "Availability domain is not available"
- **Causa**: AD incorrecto para la región
- **Solución**: Verificar ADs disponibles con `oci iam availability-domain list`

### Error: "Policy already exists"
- **Causa**: Recursos IAM ya creados
- **Solución**: Cambiar nombres en terraform.tfvars o importar recursos existentes

## Node Pool Creation Issues - Experiencia Real

### Problemas Experimentados

1. **Incompatibilidad Shape-Imagen**: 
   - Error frecuente: "Node shape and image are not compatible"
   - Terraform no maneja bien la auto-detección de imágenes compatibles
   - Las imágenes hardcodeadas fallan entre regiones

2. **Availability Domains Incorrectos**:
   - Los ADs varían entre regiones y no son predecibles
   - Formato: `WBkQ:SA-BOGOTA-1-AD-1` vs `Uocm:US-ASHBURN-AD-1`

3. **Versiones de Kubernetes**:
   - No todas las versiones están disponibles en todas las regiones
   - v1.34.1 puede no estar disponible, usar v1.32.1 o v1.31.1

### Recomendación Final

**USAR PORTAL CLOUD** para crear node pools es la solución más confiable:
- Auto-selección de imágenes compatibles
- Validación automática de configuraciones
- Menos propenso a errores de compatibilidad
- Después importar a Terraform para mantener el estado