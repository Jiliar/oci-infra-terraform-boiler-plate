#!/bin/bash

# Script para verificar el estado de los módulos de Terraform OCI
# Uso: ./check-terraform-status.sh <environment>
# Environments: dev, test, staging, prod

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
    echo -e "${YELLOW}Uso: $0 <environment>${NC}"
    echo -e "${YELLOW}Ambientes válidos: dev, test, staging, prod${NC}"
    exit 1
fi

ENV=$1

# Validar ambiente
case $ENV in
    dev|test|staging|prod)
        ;;
    *)
        echo -e "${RED}❌ Error: Ambiente '$ENV' no válido${NC}"
        echo -e "${YELLOW}Ambientes válidos: dev, test, staging, prod${NC}"
        exit 1
        ;;
esac

# Cambiar al directorio del ambiente
ENV_DIR="$ENV"
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}❌ Error: Directorio '$ENV_DIR' no existe${NC}"
    exit 1
fi

cd "$ENV_DIR"

echo -e "${BLUE}=== Estado de Módulos Terraform OCI - Ambiente: ${YELLOW}$ENV${BLUE} ===${NC}\n"

# Verificar si terraform está inicializado
if [ ! -d ".terraform" ]; then
    echo -e "${RED}❌ Terraform no está inicializado en $ENV. Ejecuta: terraform init${NC}"
    exit 1
fi

# Obtener lista de recursos del estado
echo -e "${YELLOW}📋 Obteniendo estado actual...${NC}\n"

# Definir módulos esperados
MODULES=(
    "module.networking"
    "module.k8s_cluster" 
    "module.database"
    "module.load_balancer"
    "module.dns"
    "module.iam"
    "module.vault"
    "module.waf"
    "module.monitoring"
    "module.ocir"
)

# Obtener recursos existentes
EXISTING_RESOURCES=$(terraform state list 2>/dev/null || echo "")

echo -e "${BLUE}📊 Estado de Módulos:${NC}\n"

for module in "${MODULES[@]}"; do
    if echo "$EXISTING_RESOURCES" | grep -q "^$module\."; then
        echo -e "  ✅ ${GREEN}$module${NC} - CREADO"
        
        # Mostrar recursos específicos del módulo
        module_resources=$(echo "$EXISTING_RESOURCES" | grep "^$module\." | wc -l)
        echo -e "     └── $module_resources recursos"
    else
        echo -e "  ❌ ${RED}$module${NC} - NO CREADO"
    fi
done

echo -e "\n${BLUE}🔍 Recursos por Módulo:${NC}\n"

for module in "${MODULES[@]}"; do
    module_resources=$(echo "$EXISTING_RESOURCES" | grep "^$module\." || true)
    if [ ! -z "$module_resources" ]; then
        echo -e "${GREEN}$module:${NC}"
        echo "$module_resources" | sed 's/^/  - /'
        echo
    fi
done

# Verificar recursos pendientes
echo -e "${BLUE}⏳ Verificando recursos pendientes...${NC}\n"

PLAN_OUTPUT=$(terraform plan -detailed-exitcode 2>/dev/null || echo "plan_failed")

if [ "$PLAN_OUTPUT" = "plan_failed" ]; then
    echo -e "${RED}❌ Error al ejecutar terraform plan${NC}"
elif echo "$PLAN_OUTPUT" | grep -q "No changes"; then
    echo -e "${GREEN}✅ Todos los recursos están sincronizados${NC}"
else
    echo -e "${YELLOW}⚠️  Hay cambios pendientes. Ejecuta: terraform plan${NC}"
fi

# Resumen
echo -e "\n${BLUE}📈 Resumen:${NC}"
total_modules=${#MODULES[@]}
created_modules=$(echo "$EXISTING_RESOURCES" | grep -E "^module\." | cut -d'.' -f1-2 | sort -u | wc -l)
total_resources=$(echo "$EXISTING_RESOURCES" | wc -l)

echo -e "  • Ambiente: ${BLUE}$ENV${NC}"
echo -e "  • Módulos creados: ${GREEN}$created_modules${NC}/$total_modules"
echo -e "  • Total recursos: ${GREEN}$total_resources${NC}"
if [ -f "terraform.tfvars" ]; then
    echo -e "  • Región: ${BLUE}$(grep 'region.*=' terraform.tfvars | cut -d'"' -f2)${NC}"
fi

# Identificar módulos faltantes y ofrecer crearlos
MISSING_MODULES=()
for module in "${MODULES[@]}"; do
    if ! echo "$EXISTING_RESOURCES" | grep -q "^$module\."; then
        MISSING_MODULES+=("$module")
    fi
done

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}🚀 Módulos faltantes detectados:${NC}"
    for module in "${MISSING_MODULES[@]}"; do
        echo -e "  • ${RED}$module${NC}"
    done
    
    echo -e "\n${BLUE}¿Deseas crear los módulos faltantes? (y/n):${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}🔨 Creando módulos faltantes...${NC}\n"
        
        for module in "${MISSING_MODULES[@]}"; do
            echo -e "${BLUE}📦 Creando $module...${NC}"
            
            if terraform apply -target="$module" -auto-approve -compact-warnings; then
                echo -e "${GREEN}✅ $module creado exitosamente${NC}\n"
            else
                echo -e "${RED}❌ Error creando $module${NC}\n"
                echo -e "${YELLOW}💡 Intenta manualmente: terraform apply -target=$module${NC}\n"
            fi
        done
        
        echo -e "${GREEN}🎉 Proceso completado. Ejecuta el script nuevamente para verificar.${NC}"
    else
        echo -e "\n${YELLOW}⏭️  Módulos no creados. Puedes crearlos manualmente.${NC}"
    fi
fi

# Comandos útiles
echo -e "\n${BLUE}🛠️  Comandos útiles:${NC}"
echo -e "  • Ver estado completo: ${YELLOW}terraform state list${NC}"
echo -e "  • Ver plan: ${YELLOW}terraform plan${NC}"
echo -e "  • Aplicar cambios: ${YELLOW}terraform apply${NC}"
echo -e "  • Crear módulo específico: ${YELLOW}terraform apply -target=module.NOMBRE${NC}"