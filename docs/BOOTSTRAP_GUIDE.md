# Guía de Bootstrap OCI - Configuración Automatizada de Infraestructura

## 📋 Descripción General

Esta guía explica el proceso automatizado de bootstrap para infraestructura OCI usando flujos de trabajo de GitHub Actions que crean y gestionan automáticamente buckets de Object Storage para el estado remoto de Terraform.

## 🎯 Propósito

**¿Por qué Bootstrap?**
- El estado de Terraform debe almacenarse remotamente para colaboración en equipo
- El bloqueo de estado previene modificaciones concurrentes
- Bootstrap crea la infraestructura necesaria para almacenar el estado
- GitHub Actions automatiza todo el proceso

**Lo que se Crea Automáticamente:**
- Bucket único de Object Storage `terraform-state` (compartido entre ambientes)
- Configuraciones de seguridad apropiadas (encriptación, versionado, acceso de lectura público)
- Sistema automatizado de respaldo de estado con archivos con marca de tiempo

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                   Proceso de Bootstrap                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Paso 1: Desplegar Bootstrap (Estado Local)                 │
│  └─> Crea: Buckets de Object Storage                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Paso 2: Configurar Backend en Cada Ambiente               │
│  └─> Actualizar backend.tf con nombres de buckets          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Paso 3: Inicializar Ambientes (Estado Remoto)             │
│  └─> terraform init migra estado a Object Storage           │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Recursos Creados Automáticamente

### Bucket de Object Storage (Almacenamiento de Estado Compartido)

**Bucket:**
- `terraform-state` (bucket único para todos los ambientes)

**Características:**
- ✅ **Versionado**: Habilitado - mantiene historial de todos los cambios de estado
- ✅ **Encriptación**: Gestionada por Oracle - archivos de estado encriptados en reposo
- ✅ **Acceso de Lectura Público**: Habilitado para compatibilidad con backend HTTP
- ✅ **Creación Automática**: Creado automáticamente por GitHub Actions si no existe
- ✅ **Respaldos de Estado**: Archivos de respaldo con marca de tiempo después de cada fase de despliegue

**Propósito:**
- Almacenar archivo `terraform.tfstate` remotamente
- Habilitar colaboración en equipo (estado compartido)
- Mantener historial de estado para rollback
- Respaldo y recuperación automática

**Ejemplo de Ubicación de Archivo de Estado:**
```
https://objectstorage.us-ashburn-1.oraclecloud.com/n/{namespace}/b/terraform-state-dev/o/terraform.tfstate
```

### Mecanismo de Bloqueo de Estado

**OCI usa backend HTTP con bloqueo:**
- Archivo de bloqueo almacenado en Object Storage
- Operaciones atómicas vía API HTTP
- Metadatos de bloqueo en metadatos del objeto

**Cómo Funciona:**
```
Usuario A: terraform apply
  └─> Crea archivo de bloqueo en bucket
  └─> Realiza cambios de infraestructura
  └─> Elimina archivo de bloqueo

Usuario B: terraform apply (mientras A está ejecutándose)
  └─> Intenta crear archivo de bloqueo
  └─> Bloqueado: Archivo de bloqueo ya existe
  └─> Espera hasta que Usuario A complete
```

## 🚀 Despliegue Automatizado vía GitHub Actions

### Prerrequisitos

**Secretos de GitHub Requeridos:**
- `OCI_USER_OCID` - Tu OCID de usuario OCI
- `OCI_TENANCY_OCID` - Tu OCID de tenancy OCI
- `OCI_FINGERPRINT` - Huella digital de tu clave API
- `OCI_PRIVATE_KEY` - Contenido de tu clave privada
- `OCI_REGION` - Tu región OCI (ej., sa-bogota-1)
- `OCI_NAMESPACE` - Tu namespace de Object Storage
- `OCI_COMPARTMENT_ID` - OCID del compartimento objetivo
- `OCI_BUCKET_NAME` - Nombre del bucket (terraform-state)
- `OCI_AUTH_TOKEN` - Token de autenticación para backend HTTP
- `DB_ADMIN_PASSWORD` - Contraseña de administrador de base de datos

**Configurar Secretos de GitHub:**
1. Ve a tu repositorio → Settings → Secrets and variables → Actions
2. Agrega cada secreto con el valor correspondiente de tu configuración OCI

### Paso 1: Disparadores de Flujo de Trabajo Automatizados

**terraform-plan.yml** (Disparado en Pull Requests):
- Verifica automáticamente si existe el bucket `terraform-state`
- Crea el bucket si no existe usando OCI CLI
- Ejecuta terraform plan para validación
- Solo se ejecuta para ambiente dev inicialmente

**terraform-apply.yml** (Disparado en Merge de PR):
- Se ejecuta en 5 fases secuenciales:
  1. **Fundamentos** (iam, vault, ocir)
  2. **Red y Seguridad** (networking, waf)
  3. **Infraestructura Core** (database, k8s_cluster)
  4. **Servicios de Red** (load_balancer, dns)
  5. **Monitoreo** (monitoring)
- Respalda automáticamente tfstate después de cada fase
- Crea archivos de respaldo con marca de tiempo en bucket

### Paso 2: Disparador Manual (Desarrollo)

**Crear un Pull Request:**
```bash
# Crear rama de feature
git checkout -b feature/initial-setup

# Hacer un pequeño cambio para disparar el workflow
echo "# Configuración inicial" >> README.md
git add README.md
git commit -m "Configuración inicial de infraestructura"
git push origin feature/initial-setup
```

**Crear PR dirigido a rama dev:**
1. Ve al repositorio de GitHub
2. Crea Pull Request de `feature/initial-setup` a `dev`
3. Observa la ejecución del workflow `terraform-plan.yml`
4. Verifica la creación del bucket en los logs del workflow

**Hacer merge del PR para disparar despliegue:**
1. Haz merge del Pull Request
2. Observa la ejecución del workflow `terraform-apply.yml`
3. Monitorea el despliegue de cada fase
4. Verifica archivos de respaldo de estado en bucket

### Paso 3: Obtener Configuración OCI

```bash
# Obtener namespace
export OCI_NAMESPACE=$(oci os ns get --query 'data' --raw-output)

# Obtener región
export OCI_REGION=$(oci iam region-subscription list --query 'data[0]."region-name"' --raw-output)

# Verificar
echo "Namespace: $OCI_NAMESPACE"
echo "Región: $OCI_REGION"
```

### Paso 4: Configurar Backend para Cada Ambiente

**Ambiente de Desarrollo:**
```bash
cd ../dev

# Backend ya configurado en backend.tf
cat backend.tf
```

**Ambiente de Pruebas:**
```bash
cd ../test
cat backend.tf
```

**Ambiente de Staging:**
```bash
cd ../staging
cat backend.tf
```

**Ambiente de Producción:**
```bash
cd ../prod
cat backend.tf
```

### Paso 5: Inicializar Cada Ambiente

**Desarrollo:**
```bash
cd environments/oci/dev

# Inicializar con backend remoto
terraform init

# Terraform preguntará si migrar el estado
# Escribe 'yes' para copiar estado local a Object Storage
```

Salida:
```
Inicializando el backend...
¿Quieres copiar el estado existente al nuevo backend?
  Se encontró estado preexistente mientras se migraba el backend "local" anterior al
  backend "http" recién configurado. No se encontró estado existente en el
  backend "http" recién configurado. ¿Quieres copiar este estado al nuevo
  backend "http"? Ingresa "yes" para copiar y "no" para comenzar con estado vacío.

  Ingresa un valor: yes

¡Backend "http" configurado exitosamente! Terraform usará automáticamente
este backend a menos que la configuración del backend cambie.
```

**Verificar estado en Object Storage:**
```bash
oci os object list --bucket-name terraform-state-dev --query 'data[*].name'

# Salida esperada:
terraform.tfstate
```

**Pruebas:**
```bash
cd ../test
terraform init
# Escribe 'yes' cuando se solicite
```

**Staging:**
```bash
cd ../staging
terraform init
# Escribe 'yes' cuando se solicite
```

**Producción:**
```bash
cd ../prod
terraform init
# Escribe 'yes' cuando se solicite
```

### Paso 6: Verificar Bloqueo de Estado

**Terminal 1:**
```bash
cd environments/oci/dev

# Iniciar una operación de larga duración
terraform apply
# No confirmes aún, déjalo esperando
```

**Terminal 2:**
```bash
cd environments/oci/dev

# Intentar ejecutar otra operación
terraform plan
```

Salida esperada:
```
Error: Error adquiriendo el bloqueo de estado

Mensaje de error: estado bloqueado
Info de Bloqueo:
  ID:        1234567890
  Ruta:      terraform-state-dev/terraform.tfstate
  Operación: OperationTypeApply
  Quién:     user@example.com
  Versión:   1.5.0
  Creado:    2024-01-15 10:30:00.000 UTC

Terraform adquiere un bloqueo de estado para proteger el estado de ser escrito
por múltiples usuarios al mismo tiempo.
```

**Cancelar Terminal 1** (Ctrl+C) y verificar que el bloqueo se libere.

## 🔍 Verificación y Pruebas

### Verificar Creación Automatizada de Bucket

**Vía Logs de GitHub Actions:**
1. Ve a la pestaña Actions en tu repositorio
2. Revisa los logs del workflow `terraform-plan.yml`
3. Busca el paso "Bootstrap Resources Check"
4. Verifica la creación del bucket o confirmación de existencia

**Vía Consola OCI:**
1. Inicia sesión en la Consola OCI
2. Navega a Object Storage & Archive Storage
3. Verifica el bucket `terraform-state`
4. Verifica que el versionado esté habilitado

### Verificar Archivos de Respaldo de Estado

**Archivos de Respaldo Automatizados:**
- `dev_phase1_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase2_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase3_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase4_YYYYMMDD_HHMMSS.tfstate`
- `dev_phase5_YYYYMMDD_HHMMSS.tfstate`

**Descargar e Inspeccionar:**
```bash
# Listar todos los archivos de respaldo
oci os object list --bucket-name terraform-state --prefix dev_phase

# Descargar respaldo específico
oci os object get --bucket-name terraform-state --name dev_phase1_20241124_143022.tfstate --file backup.json

# Ver contenido del respaldo
cat backup.json | jq '.version'
cat backup.json | jq '.resources | length'
```

## 🔧 Solución de Problemas

### Problema: Bucket Ya Existe

**Error:**
```
Error: 409-Conflict, BucketAlreadyExists
```

**Solución:**
```bash
# Verificar si el bucket existe
oci os bucket get --bucket-name terraform-state-dev

# Si existe, importarlo
terraform import oci_objectstorage_bucket.dev terraform-state-dev
```

### Problema: Bloqueo de Estado Atascado

**Error:**
```
Error: Error adquiriendo el bloqueo de estado
```

**Solución:**
```bash
# Forzar desbloqueo (usar con precaución)
terraform force-unlock <LOCK_ID>

# O eliminar archivo de bloqueo de Object Storage
oci os object delete --bucket-name terraform-state-dev --object-name terraform.tfstate.lock --force
```

### Problema: Acceso Denegado a Object Storage

**Error:**
```
Error: Service error:NotAuthenticated. La información requerida para completar la autenticación no fue proporcionada
```

**Solución:**
```bash
# Reconfigurar OCI CLI
oci setup config

# O establecer variables de entorno
export OCI_CLI_USER=<user_ocid>
export OCI_CLI_TENANCY=<tenancy_ocid>
export OCI_CLI_REGION=<region>
export OCI_CLI_KEY_FILE=<ruta_a_clave_privada>
```

## 📊 Estructura Final

```
.github/workflows/
├── terraform-plan.yml    # Auto-creates bucket, runs plans
└── terraform-apply.yml   # Sequential deployment + state backup

environments/oci/
├── dev/
│   ├── backend.tf           # Points to terraform-state bucket
│   ├── main.tf              # Infrastructure modules
│   ├── terraform.tfvars     # Tokenized variables
│   └── (state in Object Storage)
│
├── test/
│   ├── backend.tf           # Points to terraform-state bucket
│   ├── main.tf
│   └── (state in Object Storage)
│
├── staging/
│   ├── backend.tf
│   ├── main.tf
│   └── (state in Object Storage)
│
└── prod/
    ├── backend.tf
    ├── main.tf
    └── (state in Object Storage)

Object Storage Bucket: terraform-state
├── dev.tfstate                    # Main state file
├── dev_phase1_20241124_143022.tfstate  # Backup files
├── dev_phase2_20241124_143045.tfstate
├── dev_phase3_20241124_143102.tfstate
├── dev_phase4_20241124_143125.tfstate
└── dev_phase5_20241124_143150.tfstate
```

## ⚠️ Notas Importantes

1. **Bootstrap completamente automatizado** - No se necesitan comandos terraform manuales
2. **Bucket compartido único** - Todos los ambientes usan el bucket `terraform-state`
3. **GitHub Actions maneja todo** - Creación de bucket, gestión de estado, respaldos
4. **Fases de despliegue secuencial** - Previene problemas de dependencias de recursos
5. **Respaldos automáticos de estado** - Archivos con marca de tiempo después de cada fase
6. **Acceso de lectura público** - Requerido para compatibilidad con backend HTTP
7. **Archivos de estado específicos por ambiente** - `dev.tfstate`, `test.tfstate`, etc.
8. **Gestión de secretos** - Todas las credenciales almacenadas en GitHub Secrets

## 🔐 Mejores Prácticas de Seguridad

1. **Restringir acceso a Object Storage** - Usar políticas IAM
2. **Habilitar versionado** - Mantener historial de estado
3. **Auditar logs de acceso** - Habilitar logging de Object Storage
4. **Usar compartimentos** - Aislar recursos
5. **Rotar claves API** - Cambiar claves regularmente
6. **Usar tenancies separados** - Aislar prod de no-prod
7. **Revisar políticas IAM** - Asegurar menor privilegio

## 📚 Recursos Adicionales

- [Documentación de Backend HTTP de Terraform](https://www.terraform.io/docs/language/settings/backends/http.html)
- [Versionado de Object Storage OCI](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingversioning.htm)
- [Políticas IAM de OCI](https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/policygetstarted.htm)
- [Gestión de Estado de Terraform](https://www.terraform.io/docs/language/state/index.html)
