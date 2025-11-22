#!/bin/bash

# OCI Terraform Manager - Script Unificado
# Funcionalidades: validación, estado, deploy y gestión de clusters Istio
# Uso: ./oci-terraform-manager.sh <comando> [argumentos]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules/oci"
ENVS_DIR="$SCRIPT_DIR/environments/oci"
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq"

show_help() {
    echo -e "${CYAN}🚀 OCI Terraform Manager${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC} $0 <comando> [argumentos]"
    echo ""
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}validate${NC}                    - Validar módulos y configuración"
    echo -e "  ${GREEN}status${NC} <env>               - Ver estado de módulos en ambiente"
    echo -e "  ${GREEN}deploy${NC} <env> [module]      - Desplegar ambiente o módulo específico"
    echo -e "  ${GREEN}istio-update${NC} <env>         - Actualizar cluster_id en Istio"
    echo -e "  ${GREEN}plan${NC} <env>                 - Ver plan de cambios"
    echo -e "  ${GREEN}destroy${NC} <env> [module]     - Destruir recursos"
    echo ""
    echo -e "${YELLOW}Ambientes:${NC} dev, test, staging, prod"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  $0 validate"
    echo -e "  $0 status dev"
    echo -e "  $0 deploy dev networking"
    echo -e "  $0 istio-update dev"
}

validate_modules() {
    echo -e "${BLUE}🔍 Validando infraestructura OCI...${NC}\n"
    
    ERRORS=0
    
    # Módulos requeridos
    REQUIRED_MODULES=("networking" "k8s-cluster" "database" "ocir" "iam" "load-balancer" "dns" "secrets" "waf" "monitoring")
    ENVIRONMENTS=("dev" "test" "staging" "prod")
    
    echo -e "${YELLOW}1️⃣  Verificando módulos...${NC}"
    for module in "${REQUIRED_MODULES[@]}"; do
        if [ -d "$MODULES_DIR/$module" ] && [ -f "$MODULES_DIR/$module/main.tf" ]; then
            echo -e "  ✅ ${GREEN}$module${NC}"
        else
            echo -e "  ❌ ${RED}$module${NC}"
            ((ERRORS++)
        fi
    done
    
    echo -e "\n${YELLOW}2️⃣  Verificando ambientes...${NC}"
    for env in "${ENVIRONMENTS[@]}"; do
        if [ -d "$ENVS_DIR/$env" ] && [ -f "$ENVS_DIR/$env/main.tf" ]; then
            echo -e "  ✅ ${GREEN}$env${NC}"
        else
            echo -e "  ❌ ${RED}$env${NC}"
            ((ERRORS++))
        fi
    done
    
    echo -e "\n${YELLOW}3️⃣  Verificando Istio...${NC}"
    for env in "${ENVIRONMENTS[@]}"; do
        if [ -d "$ENVS_DIR/$env/istio" ] && [ -f "$ENVS_DIR/$env/istio/main.tf" ]; then
            echo -e "  ✅ ${GREEN}$env/istio${NC}"
        else
            echo -e "  ⚠️  ${YELLOW}$env/istio${NC} - no configurado"
        fi
    done
    
    if [ $ERRORS -eq 0 ]; then
        echo -e "\n${GREEN}✅ Validación completada exitosamente${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Se encontraron $ERRORS errores${NC}"
        return 1
    fi
}

check_terraform_status() {
    local env=$1
    
    if [ -z "$env" ]; then
        echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
        return 1
    fi
    
    local env_dir="$ENVS_DIR/$env"
    
    if [ ! -d "$env_dir" ]; then
        echo -e "${RED}❌ Error: Ambiente '$env' no existe${NC}"
        return 1
    fi
    
    cd "$env_dir"
    
    echo -e "${BLUE}📊 Estado de Terraform - Ambiente: ${YELLOW}$env${NC}\n"
    
    # Verificar inicialización
    if [ ! -d ".terraform" ]; then
        echo -e "${RED}❌ Terraform no inicializado. Ejecuta: terraform init${NC}"
        return 1
    fi
    
    # Módulos esperados
    local modules=("networking" "k8s_cluster" "database" "load_balancer" "dns" "iam" "vault" "waf" "monitoring" "ocir")
    local existing_resources=$(terraform state list 2>/dev/null || echo "")
    
    echo -e "${YELLOW}📋 Estado de módulos:${NC}"
    local created=0
    
    for module in "${modules[@]}"; do
        if echo "$existing_resources" | grep -q "^module.$module\."; then
            local count=$(echo "$existing_resources" | grep "^module.$module\." | wc -l)
            echo -e "  ✅ ${GREEN}module.$module${NC} ($count recursos)"
            ((created++))
        else
            echo -e "  ❌ ${RED}module.$module${NC} - no creado"
        fi
    done
    
    echo -e "\n${BLUE}📈 Resumen:${NC}"
    echo -e "  • Módulos creados: ${GREEN}$created${NC}/${#modules[@]}"
    echo -e "  • Total recursos: ${GREEN}$(echo "$existing_resources" | wc -l)${NC}"
    
    # Verificar cambios pendientes
    if terraform plan -detailed-exitcode >/dev/null 2>&1; then
        echo -e "  • Estado: ${GREEN}Sincronizado${NC}"
    else
        echo -e "  • Estado: ${YELLOW}Cambios pendientes${NC}"
    fi
}

deploy_infrastructure() {
    local env=$1
    local module=$2
    
    if [ -z "$env" ]; then
        echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
        return 1
    fi
    
    local env_dir="$ENVS_DIR/$env"
    
    if [ ! -d "$env_dir" ]; then
        echo -e "${RED}❌ Error: Ambiente '$env' no existe${NC}"
        return 1
    fi
    
    cd "$env_dir"
    
    echo -e "${BLUE}🚀 Desplegando en ambiente: ${YELLOW}$env${NC}"
    
    # Inicializar si es necesario
    if [ ! -d ".terraform" ]; then
        echo -e "${YELLOW}🔧 Inicializando Terraform...${NC}"
        terraform init
    fi
    
    if [ -n "$module" ]; then
        echo -e "${YELLOW}📦 Desplegando módulo: $module${NC}"
        terraform apply -target="module.$module" -auto-approve
    else
        echo -e "${YELLOW}🏗️  Desplegando infraestructura completa...${NC}"
        terraform apply -auto-approve
    fi
    
    echo -e "${GREEN}✅ Despliegue completado${NC}"
}

update_istio_cluster_id() {
    local env=$1
    
    if [ -z "$env" ]; then
        echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
        return 1
    fi
    
    local istio_dir="$ENVS_DIR/$env/istio"
    local tfvars_file="$istio_dir/terraform.tfvars"
    
    if [ ! -d "$istio_dir" ]; then
        echo -e "${RED}❌ Error: Istio no configurado para '$env'${NC}"
        return 1
    fi
    
    if [ ! -f "$tfvars_file" ]; then
        echo -e "${RED}❌ Error: $tfvars_file no existe${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 Actualizando cluster_id para Istio en: ${YELLOW}$env${NC}\n"
    
    # Obtener clusters activos
    local clusters=$(oci ce cluster list --compartment-id "$COMPARTMENT_ID" --query "data[?\"lifecycle-state\"=='ACTIVE'].{id:id,name:name}" --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error: No se pudo conectar a OCI${NC}"
        return 1
    fi
    
    local cluster_count=$(echo "$clusters" | jq length)
    
    if [ "$cluster_count" -eq 0 ]; then
        echo -e "${RED}❌ No se encontraron clusters activos${NC}"
        return 1
    elif [ "$cluster_count" -eq 1 ]; then
        local cluster_id=$(echo "$clusters" | jq -r '.[0].id')
        local cluster_name=$(echo "$clusters" | jq -r '.[0].name')
        echo -e "${GREEN}✅ Único cluster encontrado: $cluster_name${NC}"
    else
        echo -e "${YELLOW}📋 Clusters disponibles:${NC}"
        
        local i=1
        declare -a cluster_array
        
        while IFS= read -r line; do
            cluster_array[i]="$line"
            local name=$(echo "$line" | jq -r '.name')
            local id=$(echo "$line" | jq -r '.id')
            echo -e "  [$i] $name"
            echo -e "      ID: $id"
            ((i++))
        done < <(echo "$clusters" | jq -c '.[]')
        
        echo ""
        read -p "Selecciona el cluster (1-$((i-1))): " selection
        
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -ge "$i" ]; then
            echo -e "${RED}❌ Selección inválida${NC}"
            return 1
        fi
        
        local selected_cluster="${cluster_array[$selection]}"
        local cluster_id=$(echo "$selected_cluster" | jq -r '.id')
        local cluster_name=$(echo "$selected_cluster" | jq -r '.name')
        
        echo -e "${GREEN}✅ Cluster seleccionado: $cluster_name${NC}"
    fi
    
    # Crear backup
    cp "$tfvars_file" "$tfvars_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Actualizar cluster_id
    if grep -q "cluster_id.*=" "$tfvars_file"; then
        sed -i.tmp "s|cluster_id.*=.*|cluster_id = \"$cluster_id\"|" "$tfvars_file"
        rm -f "$tfvars_file.tmp"
        echo -e "${GREEN}✅ cluster_id actualizado en $tfvars_file${NC}"
        
        # Verificar cambio
        echo -e "${BLUE}🔍 Verificación:${NC}"
        grep "cluster_id" "$tfvars_file"
    else
        echo -e "${RED}❌ No se encontró la variable cluster_id${NC}"
        return 1
    fi
}

terraform_plan() {
    local env=$1
    
    if [ -z "$env" ]; then
        echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
        return 1
    fi
    
    local env_dir="$ENVS_DIR/$env"
    
    if [ ! -d "$env_dir" ]; then
        echo -e "${RED}❌ Error: Ambiente '$env' no existe${NC}"
        return 1
    fi
    
    cd "$env_dir"
    
    echo -e "${BLUE}📋 Plan de Terraform - Ambiente: ${YELLOW}$env${NC}\n"
    
    if [ ! -d ".terraform" ]; then
        echo -e "${YELLOW}🔧 Inicializando Terraform...${NC}"
        terraform init
    fi
    
    terraform plan
}

destroy_infrastructure() {
    local env=$1
    local module=$2
    
    if [ -z "$env" ]; then
        echo -e "${RED}❌ Error: Debes especificar el ambiente${NC}"
        return 1
    fi
    
    local env_dir="$ENVS_DIR/$env"
    
    if [ ! -d "$env_dir" ]; then
        echo -e "${RED}❌ Error: Ambiente '$env' no existe${NC}"
        return 1
    fi
    
    cd "$env_dir"
    
    echo -e "${RED}🗑️  DESTRUYENDO recursos en: ${YELLOW}$env${NC}"
    echo -e "${YELLOW}⚠️  Esta acción es IRREVERSIBLE${NC}"
    
    read -p "¿Estás seguro? Escribe 'yes' para confirmar: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}❌ Operación cancelada${NC}"
        return 1
    fi
    
    if [ -n "$module" ]; then
        echo -e "${RED}🗑️  Destruyendo módulo: $module${NC}"
        terraform destroy -target="module.$module" -auto-approve
    else
        echo -e "${RED}🗑️  Destruyendo infraestructura completa...${NC}"
        terraform destroy -auto-approve
    fi
    
    echo -e "${GREEN}✅ Destrucción completada${NC}"
}

# Función principal
main() {
    case "${1:-}" in
        "validate")
            validate_modules
            ;;
        "status")
            check_terraform_status "$2"
            ;;
        "deploy")
            deploy_infrastructure "$2" "$3"
            ;;
        "istio-update")
            update_istio_cluster_id "$2"
            ;;
        "plan")
            terraform_plan "$2"
            ;;
        "destroy")
            destroy_infrastructure "$2" "$3"
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"