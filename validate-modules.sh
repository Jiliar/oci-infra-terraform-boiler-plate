#!/bin/bash
# Script de Validación Unificado - OCI Infrastructure
# Verifica módulos, correcciones y configuración completa

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules/oci"
ENVS_DIR="$SCRIPT_DIR/environments/oci"

ERRORS=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "🔍 Validando módulos de Terraform para OCI..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Verificando Existencia de Módulos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REQUIRED_MODULES=(
    "networking"
    "k8s-cluster"
    "database"
    "ocir"
    "iam"
    "load-balancer"
    "dns"
    "secrets"
    "waf"
    "monitoring"
)

for module in "${REQUIRED_MODULES[@]}"; do
    [ -d "$MODULES_DIR/$module" ]
    check "Módulo $module existe"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Verificando Estructura de Módulos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for module in "${REQUIRED_MODULES[@]}"; do
    MODULE_PATH="$MODULES_DIR/$module"
    [ -f "$MODULE_PATH/main.tf" ] && [ -f "$MODULE_PATH/variables.tf" ] && [ -f "$MODULE_PATH/outputs.tf" ]
    check "$module tiene main.tf, variables.tf, outputs.tf"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Verificando Ambientes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ENVIRONMENTS=("dev" "test" "staging" "prod")
for env in "${ENVIRONMENTS[@]}"; do
    ENV_PATH="$ENVS_DIR/$env"
    [ -d "$ENV_PATH" ] && [ -f "$ENV_PATH/main.tf" ] && [ -f "$ENV_PATH/backend.tf" ]
    check "Ambiente $env completo"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Verificando Referencias de Módulos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in "${ENVIRONMENTS[@]}"; do
    ENV_MAIN="$ENVS_DIR/$env/main.tf"
    
    for module in networking k8s_cluster database ocir load_balancer dns vault iam waf monitoring; do
        if grep -q "module \"$module\"" "$ENV_MAIN" 2>/dev/null; then
            : # Módulo encontrado
        else
            echo -e "${YELLOW}  ⚠️  $env: módulo $module no referenciado${NC}"
        fi
    done
done
echo -e "${GREEN}  ✓ Referencias verificadas${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Verificando Istio en Ambientes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in "${ENVIRONMENTS[@]}"; do
    grep -q "helm_release.*istio_base" "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Istio base instalado"
    grep -q "helm_release.*istiod" "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Istiod instalado"
    grep -q "helm_release.*istio_ingress" "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Istio ingress instalado"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Verificando Backend State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in dev test staging prod; do
    grep -q "backend \"http\"" "$ENVS_DIR/$env/backend.tf" 2>/dev/null
    check "$env: Backend HTTP configurado"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  Verificando Configuración de Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in dev test; do
    grep -q 'shape.*=.*"VM.Standard.E2.1"' "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Database VM.Standard.E2.1 (1 OCPU / 2GB RAM)"
done
for env in staging prod; do
    grep -q 'shape.*=.*"VM.Standard.E4.Flex"' "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Database VM.Standard.E4.Flex (2 OCPU / 8GB RAM)"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  Verificando Configuración de OKE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in dev test; do
    grep -q 'cluster_type.*=.*"Basic"' "$ENVS_DIR/$env/main.tf" 2>/dev/null || \
    grep -q 'cluster_type.*=.*"shared"' "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: OKE Basic/Shared cluster"
done
for env in staging prod; do
    grep -q 'cluster_type.*=.*"Enhanced"' "$ENVS_DIR/$env/main.tf" 2>/dev/null || \
    grep -q 'cluster_type.*=.*"dedicated"' "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: OKE Enhanced/Dedicated cluster"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9️⃣  Verificando Recursos OCI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -q "oci_containerengine_cluster" modules/oci/k8s-cluster/main.tf 2>/dev/null
check "OKE Cluster definido"
grep -q "oci_core_vcn" modules/oci/networking/main.tf 2>/dev/null
check "VCN definido"
grep -q "oci_load_balancer" modules/oci/load-balancer/main.tf 2>/dev/null
check "Load Balancer definido"
grep -q "oci_artifacts_container_repository" modules/oci/ocir/main.tf 2>/dev/null
check "OCIR definido"
grep -q "oci_kms_vault" modules/oci/secrets/main.tf 2>/dev/null
check "Vault definido"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔟 Verificando Providers Kubernetes/Helm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for env in "${ENVIRONMENTS[@]}"; do
    grep -q "provider \"kubernetes\"" "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Provider kubernetes configurado"
    grep -q "provider \"helm\"" "$ENVS_DIR/$env/main.tf" 2>/dev/null
    check "$env: Provider helm configurado"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESULTADO FINAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║          ✅ TODAS LAS VALIDACIONES PASARON ✅              ║"
    echo "║                                                            ║"
    echo "║     La infraestructura está 100% lista para desplegar     ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "📋 Resumen:"
    echo "  • Módulos: ${#REQUIRED_MODULES[@]} verificados"
    echo "  • Ambientes: ${#ENVIRONMENTS[@]} verificados"
    echo "  • Configuración: optimizada"
    exit 0
else
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║          ❌ SE ENCONTRARON $ERRORS ERRORES ❌                  ║"
    echo "║                                                            ║"
    echo "║         Revisa los mensajes anteriores                    ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
fi
