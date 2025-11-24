# Guía de Workflows de GitHub Actions - Infraestructura OCI

## 📋 Descripción General

Esta guía explica los workflows de GitHub Actions para desplegar infraestructura OCI usando Terraform. Los workflows automatizan la validación y despliegue en todos los entornos (dev, test, staging, prod) con estrategia de despliegue modular.

## 🔄 Orden de Ejecución de Workflows

### 1️⃣ **Terraform Plan** (Fase de Validación)

**Archivo:** `.github/workflows/terraform-plan.yml`  
**Activador:** Pull Request `[opened, synchronize, reopened]` a ramas `[dev, test, staging, main]`  
**Propósito:** Validar sintaxis de Terraform y previsualizar cambios de infraestructura  
**Estrategia:** Despliegue matrix en 10 módulos por entorno

**Matriz de Módulos:**
- `networking` - VCN, subnets, gateways, security lists
- `k8s_cluster` - Cluster OKE (solo control plane)
- `database` - Servicios gestionados PostgreSQL
- `ocir` - Oracle Container Image Registry
- `load_balancer` - Balanceador de Carga OCI
- `dns` - Gestión DNS de OCI
- `vault` - OCI Vault para secretos
- `iam` - Gestión de Identidad y Acceso
- `waf` - Web Application Firewall
- `monitoring` - Monitoreo y logging de OCI

**Pasos Ejecutados:**
1. Descargar código
2. Configurar Terraform 1.5.0
3. Establecer entorno basado en rama destino (`github.event.pull_request.base.ref`)
4. Configurar OCI CLI con claves API (solo dev)
5. Verificación de recursos bootstrap (solo dev)
6. Configurar variables de Terraform desde secrets
7. `terraform init` - Inicializar backend y providers
8. `terraform plan` - Generar plan de ejecución por módulo

### 2️⃣ **Terraform Apply** (Fase de Despliegue)

**Archivo:** `.github/workflows/terraform-apply.yml`  
**Activador:** Pull Request `[closed]` con `merged == true` a ramas `[dev, test, staging, main]`  
**Propósito:** Desplegar cambios de infraestructura a OCI después de validación exitosa  
**Estrategia:** Despliegue secuencial en 5 fases con `max-parallel: 1`

## 🔗 Fases de Despliegue Secuencial

### **Fase 1 - Fundamentos** (Desplegar Primero)
- `iam` ✅ - Políticas, grupos, usuarios (requerido por todo)
- `vault` ✅ - Gestión de secretos (requerido por DB, k8s)
- `ocir` ✅ - Registro de contenedores (requerido por k8s)

### **Fase 2 - Red y Seguridad**
- `networking` ✅ - VCN, subnets, security lists
- `waf` ✅ - Web Application Firewall (depende de networking)

### **Fase 3 - Infraestructura Core**
- `database` ✅ - Bases de datos (depende de networking)
- `k8s_cluster` ✅ - Kubernetes (depende de networking, iam, ocir)

### **Fase 4 - Servicios de Red Avanzados**
- `load_balancer` ✅ - Balanceador de Carga (depende de k8s_cluster, networking)
- `dns` ✅ - Registros DNS (depende de load_balancer)

### **Fase 5 - Monitoreo** (Desplegar Último)
- `monitoring` ✅ - (depende de k8s_cluster, load_balancer)

**Características del Workflow:**
1. **Ejecución Secuencial**: `max-parallel: 1` - una fase a la vez
2. **Backup Automático**: Estado respaldado después de cada fase
3. **Validación Final**: Job separado para verificar estado
4. **Solo Dev**: Bootstrap y backup solo en entorno dev

**Pasos Ejecutados:**
1. **Job Apply** (5 fases secuenciales):
   - Descargar código
   - Configurar Terraform 1.5.0
   - Establecer entorno basado en rama destino
   - Configurar OCI CLI con claves API (solo dev)
   - Verificar/crear bucket terraform-state (solo dev)
   - Configurar variables de Terraform desde secrets
   - `terraform init` - Inicializar backend y providers
   - **Fase 1**: Desplegar iam, vault, ocir + backup estado
   - **Fase 2**: Desplegar networking, waf + backup estado
   - **Fase 3**: Desplegar database, k8s_cluster + backup estado
   - **Fase 4**: Desplegar load_balancer, dns + backup estado
   - **Fase 5**: Desplegar monitoring + backup estado
   - Apply final completo (solo en fase 5)
2. **Job validate-state**:
   - Validar configuración y estado final

## 🚀 Flujo Completo de Despliegue

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Desarrollador modifica archivos Terraform                │
│    └─> environments/oci/dev/main.tf                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Crear Pull Request a dev/test/staging/main               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. terraform-plan.yml se activa automáticamente            │
│    ├─> Ejecuta para: entorno según rama destino            │
│    ├─> Verifica/crea bucket (solo dev)                     │
│    ├─> terraform init                                       │
│    ├─> terraform validate                                   │
│    └─> terraform plan (10 módulos en paralelo)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Revisar salida del plan en GitHub Actions               │
│    └─> Verificar recursos a crear/modificar/destruir        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Mergear Pull Request                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. terraform-apply.yml se activa automáticamente           │
│    ├─> 5 fases secuenciales (max-parallel: 1)              │
│    ├─> Backup de estado después de cada fase (solo dev)    │
│    ├─> terraform apply -auto-approve por módulo            │
│    └─> Validación final de estado                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. Infraestructura OCI Desplegada ✅                       │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Prerequisites

### 1. OCI Tenancy Setup

**Required:**
- OCI Tenancy with proper permissions
- Compartment for resources
- Object Storage buckets for Terraform state

### 2. OCI API Key for GitHub Actions

**Create API Key:**
```bash
# Generate API key pair
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Display public key (upload to OCI console)
cat ~/.oci/oci_api_key_public.pem
```

**Upload Public Key to OCI:**
1. Go to OCI Console → User Settings
2. Click **API Keys**
3. Click **Add API Key**
4. Paste public key content
5. Note the fingerprint

**Get Required OCIDs:**
```bash
# Get user OCID
oci iam user list --query 'data[0].id' --raw-output

# Get tenancy OCID
oci iam tenancy get --tenancy-id $(oci iam user list --query 'data[0]."compartment-id"' --raw-output) --query 'data.id' --raw-output

# Get compartment OCID
oci iam compartment list --query 'data[0].id' --raw-output

# Get availability domain
oci iam availability-domain list --compartment-id $TENANCY_OCID --query 'data[0].name' --raw-output
```

### 3. Configuración de Backend de Object Storage

**El bucket se crea automáticamente:**
```bash
# El workflow terraform-plan.yml crea automáticamente el bucket si no existe
# Solo necesitas obtener el namespace para configurar los secrets

# Obtener namespace
export OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)
echo "Tu namespace es: $OCI_NAMESPACE"

# El bucket 'terraform-state' se creará automáticamente con:
# - Acceso público de lectura (ObjectRead)
# - Versionado habilitado
# - Compartido entre todos los entornos
```

### 4. Install Required Tools

#### Terraform

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version
```

**Linux:**
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip

# Unzip and install
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

#### OCI CLI

**macOS/Linux:**
```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config

# Verify installation
oci --version
```

**Windows:**
```powershell
# Download installer from:
# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm

# Run installer and follow prompts

# Verify installation
oci --version
```

## 📝 GitHub Repository Setup

### 1. Add Workflows to Repository

```bash
# Navigate to your repository
cd your-terraform-repo

# Create workflows directory
mkdir -p .github/workflows

# Copy OCI workflows
cp libs/pyinfrastructure-terraform-gen/references/oci/.github/workflows/* .github/workflows/

# Commit workflows
git add .github/workflows/
git commit -m "Add Terraform CI/CD workflows"
git push origin main
```

### 2. Configure GitHub Secrets

**Navigate to GitHub:**
1. Go to your repository on GitHub
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

## 🔐 Secrets Requeridos de GitHub

### Secrets de Autenticación OCI Principales

| Nombre del Secret | Descripción | Valor de Ejemplo | Requerido |
|-------------------|--------------|------------------|----------|
| `OCI_USER_OCID` | OCID del Usuario OCI | `ocid1.user.oc1..aaaaaaaa...` | ✅ |
| `OCI_TENANCY_OCID` | OCID del Tenancy OCI | `ocid1.tenancy.oc1..aaaaaaaa...` | ✅ |
| `OCI_FINGERPRINT` | Huella Digital de Clave API | `aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99` | ✅ |
| `OCI_PRIVATE_KEY` | Contenido de Clave Privada | `-----BEGIN RSA PRIVATE KEY-----\n...` | ✅ |
| `OCI_REGION` | Región OCI | `sa-bogota-1` | ✅ |
| `OCI_COMPARTMENT_ID` | OCID del Compartimento Destino | `ocid1.compartment.oc1..aaaaaaaa...` | ✅ |
| `OCI_NAMESPACE` | Namespace de Object Storage | `ax7ur15nzqvd` | ✅ |
| `OCI_BUCKET_NAME` | Nombre del Bucket de Estado | `terraform-state` | ✅ |
| `OCI_AUTH_TOKEN` | Token de Autenticación HTTP | `token-auth-123456` | ✅ |

### Secrets de Base de Datos

| Nombre del Secret | Descripción | Valor de Ejemplo | Requerido |
|-------------------|--------------|------------------|----------|
| `DB_ADMIN_PASSWORD` | Contraseña de Admin de BD | `SecureP@ssw0rd123!` | ✅ |

**Nota:** Solo se requieren los secrets listados arriba. Los workflows actuales han sido simplificados y no requieren secrets adicionales para SSL, monitoreo o servicios externos.

### Cómo Agregar Secrets al Repositorio de GitHub

#### Paso 1: Navegar a Configuración del Repositorio
1. Ve a tu repositorio de GitHub
2. Haz clic en **Settings** (pestaña superior)
3. Haz clic en **Secrets and variables** → **Actions** (menú izquierdo)
4. Haz clic en **New repository secret**

#### Paso 2: Crear Cada Secret Individualmente

**Formato para cada secret:**
```
Nombre: [NOMBRE_EXACTO_DEL_SECRET]
Valor: [VALOR_SIN_COMILLAS]
```

**Secrets Requeridos a Crear:**

**Secret 1:**
```
Nombre: OCI_USER_OCID
Valor: ocid1.user.oc1..aaaaaaaa...
```

**Secret 2:**
```
Nombre: OCI_TENANCY_OCID
Valor: ocid1.tenancy.oc1..aaaaaaaa...
```

**Secret 3:**
```
Nombre: OCI_FINGERPRINT
Valor: aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99
```

**Secret 4:**
```
Nombre: OCI_PRIVATE_KEY
Valor: -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
```

**Secret 5:**
```
Nombre: OCI_REGION
Valor: sa-bogota-1
```

**Secret 6:**
```
Nombre: OCI_COMPARTMENT_ID
Valor: ocid1.compartment.oc1..aaaaaaaa...
```

**Secret 7:**
```
Nombre: OCI_NAMESPACE
Valor: ax7ur15nzqvd
```

**Secret 8:**
```
Nombre: OCI_BUCKET_NAME
Valor: terraform-state
```

**Secret 9:**
```
Nombre: OCI_AUTH_TOKEN
Valor: token-auth-123456
```

**Secret 10:**
```
Nombre: DB_ADMIN_PASSWORD
Valor: SecureP@ssw0rd123!
```

#### Step 3: Get OCI Values

**Get OCIDs using OCI CLI:**
```bash
# Get User OCID
oci iam user list --query 'data[0].id' --raw-output

# Get Tenancy OCID
oci iam tenancy get --tenancy-id $(oci iam user list --query 'data[0]."compartment-id"' --raw-output) --query 'data.id' --raw-output

# Get Compartment OCID
oci iam compartment list --query 'data[0].id' --raw-output

# Get Availability Domain
oci iam availability-domain list --compartment-id $TENANCY_OCID --query 'data[0].name' --raw-output
```

**Create API Key Pair:**
```bash
# Generate API key pair
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Display public key (upload to OCI Console)
cat ~/.oci/oci_api_key_public.pem

# Display private key (copy to GitHub Secret OCI_PRIVATE_KEY)
cat ~/.oci/oci_api_key.pem
```

**Upload Public Key to OCI:**
1. Go to OCI Console → User Settings
2. Click **API Keys**
3. Click **Add API Key**
4. Paste public key content
5. Note the fingerprint (use for OCI_FINGERPRINT secret)

#### Step 4: Verify Secrets
After creating all secrets, verify they appear in the repository secrets list with correct names.

### Secret Validation Commands

```bash
# Validate OCI credentials locally
oci iam user get --user-id $OCI_USER_OCID
oci iam compartment get --compartment-id $OCI_COMPARTMENT_ID
oci iam availability-domain list --compartment-id $OCI_TENANCY_OCID

# Test API key authentication
oci iam region list
```

### 4. Verificar Configuración de Backend

Cada entorno ya tiene la configuración correcta de backend:

**Archivo:** `environments/oci/dev/backend.tf`
```hcl
terraform {
  backend "http" {
    address        = "https://objectstorage.sa-bogota-1.oraclecloud.com/n/ax7ur15nzqvd/b/terraform-state/o/dev.tfstate"
    update_method  = "PUT"
    lock_address   = "https://objectstorage.sa-bogota-1.oraclecloud.com/n/ax7ur15nzqvd/b/terraform-state/o/dev.tfstate"
    lock_method    = "PUT"
    unlock_address = "https://objectstorage.sa-bogota-1.oraclecloud.com/n/ax7ur15nzqvd/b/terraform-state/o/dev.tfstate"
    unlock_method  = "DELETE"
  }
}
```

**Nota:** Cada entorno (dev/test/staging/prod) usa el mismo bucket pero archivos de estado separados.

## 🎯 Ejemplos de Uso

### Ejemplo 1: Desplegar al Entorno Dev

```bash
# 1. Crear rama de feature
git checkout -b feature/actualizar-infraestructura-dev

# 2. Modificar configuración de Terraform
vim environments/oci/dev/main.tf

# Actualizar módulo de base de datos
module "database" {
  source = "../../../modules/oci/database"
  
  db_system_name = "postgres-dev"
  shape_name     = "VM.Standard.E2.1"
  # ... otros parámetros
}

# 3. Hacer commit de los cambios
git add environments/oci/dev/main.tf
git commit -m "Actualizar configuración de BD OCI para dev"

# 4. Crear Pull Request a rama dev
git push origin feature/actualizar-infraestructura-dev
# Crear PR en GitHub apuntando a rama 'dev'

# → terraform-plan.yml se ejecuta automáticamente (10 módulos)
# → Al mergear: terraform-apply.yml se ejecuta (5 fases secuenciales)
# → Infraestructura desplegada al entorno dev de OCI
```

### Ejemplo 2: Desplegar al Entorno de Producción

```bash
# 1. Actualizar configuración de producción
vim environments/oci/prod/main.tf

# Cambiar: kubernetes_version = "v1.28.2"

# 2. Hacer commit y crear PR a rama main
git add environments/oci/prod/main.tf
git commit -m "Actualizar OKE a versión 1.28.2 en producción"
git push origin feature/update-k8s-prod
# Crear PR en GitHub apuntando a rama 'main'

# → terraform-plan.yml se ejecuta automáticamente
# → Al mergear: terraform-apply.yml se ejecuta (5 fases secuenciales)
# → Infraestructura de producción actualizada
```

### Ejemplo 3: Despliegue Basado en Ramas

```bash
# Desplegar a diferentes entornos creando PR a ramas específicas

# Desplegar a dev
# Crear PR apuntando a rama 'dev'
# → Despliega al entorno dev

# Desplegar a test
# Crear PR apuntando a rama 'test'
# → Despliega al entorno test

# Desplegar a staging
# Crear PR apuntando a rama 'staging'
# → Despliega al entorno staging

# Desplegar a producción
# Crear PR apuntando a rama 'main'
# → Despliega al entorno prod
```

## 🔍 Monitoreo y Solución de Problemas

### Ver Ejecuciones de Workflow

1. Ve a la pestaña **Actions** en el repositorio de GitHub
2. Selecciona workflow: "Terraform Plan" o "Terraform Apply"
3. Haz clic en una ejecución específica para ver detalles
4. Haz clic en el entorno o fase para ver logs

### Problemas Comunes y Soluciones

**Problema 1: Fallo de Autenticación**
```
Error: Service error:NotAuthenticated
```

**Solución:**
- Verificar que todos los secrets de OCI estén configurados correctamente
- Verificar que la huella digital de la clave API coincida
- Asegurar que la clave privada esté completa y válida

**Problema 2: Fallo de Inicialización de Backend**
```
Error: Failed to configure backend: bucket doesn't exist
```

**Solución:**
- El workflow crea automáticamente el bucket en el entorno dev
- Para otros entornos, verificar que OCI_BUCKET_NAME y OCI_NAMESPACE sean correctos
- El bucket se comparte entre todos los entornos

**Problema 3: Recursos Bootstrap No Encontrados**
```
Error: Compartment not found
```

**Solución:**
```bash
# Verificar que el compartimento existe
oci iam compartment get --compartment-id $OCI_COMPARTMENT_ID

# Actualizar secrets de GitHub con valores correctos
```

**Problema 4: Fallo de Despliegue de Módulo**
```
Error: Module k8s_cluster failed to apply
```

**Solución:**
- Verificar que las fases anteriores se completaron exitosamente
- k8s_cluster requiere networking, iam, ocir de fases previas
- Revisar logs del módulo en GitHub Actions
- Para k8s_cluster: Solo se despliega el control plane, node pools excluidos
- Verificar límites de tenancy de OCI

### Debug Locally

```bash
# Navigate to environment
cd environments/oci/dev

# Configure OCI CLI
oci setup config

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes (if needed)
terraform apply
```

## ⚠️ Notas Importantes

### Mejores Prácticas de Seguridad

1. **Nunca hacer commit de claves API** al repositorio
2. **Usar políticas IAM de menor privilegio** para producción
3. **Habilitar MFA** en cuentas de OCI
4. **Rotar claves API** regularmente (cada 90 días)
5. **Habilitar Cloud Guard** para monitoreo de seguridad
6. **Usar compartimentos separados** para dev/staging/prod
7. **Versionado automático** habilitado en bucket de estado
8. **Revisar políticas IAM** regularmente

### Consideraciones de Workflow

1. **Despliegue Basado en Ramas**: Cada rama despliega a entorno específico
   - rama `dev` → entorno dev
   - rama `test` → entorno test  
   - rama `staging` → entorno staging
   - rama `main` → entorno prod
2. **Despliegue Secuencial**: 5 fases secuenciales con `max-parallel: 1`
3. **Auto-aprobación**: Apply workflow usa `-auto-approve`
4. **Bootstrap Automático**: Entorno dev crea bucket automáticamente
5. **Cluster K8s**: Solo control plane se despliega, node pools excluidos
6. **Aislamiento de Entornos**: Cada entorno tiene archivo de estado separado
7. **Backup Automático**: Estado respaldado después de cada fase (solo dev)
8. **Bucket Compartido**: Todos los entornos usan el mismo bucket terraform-state

## 📚 Additional Resources

- [Terraform OCI Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OCI IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policygetstarted.htm)
- [Terraform HTTP Backend](https://www.terraform.io/docs/language/settings/backends/http.html)
- [OCI CLI Command Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)
