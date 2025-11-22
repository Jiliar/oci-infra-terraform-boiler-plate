#!/bin/bash

# Script para actualizar cluster_id en terraform.tfvars de Istio
# Uso: ./update-istio-cluster-id.sh <environment>
# Ejemplo: ./update-istio-cluster-id.sh dev

if [ $# -eq 0 ]; then
    echo "❌ Error: Debes especificar el ambiente"
    echo "Uso: $0 <environment>"
    echo "Ambientes disponibles: dev, test, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaa2thzjlengvmdm4omm7hcfsxylki5ucbxsej7frpgq25jnarlhpuq"
ISTIO_DIR="environments/oci/$ENVIRONMENT/istio"
TFVARS_FILE="$ISTIO_DIR/terraform.tfvars"

# Validar que el ambiente existe
if [ ! -d "$ISTIO_DIR" ]; then
    echo "❌ Error: El ambiente '$ENVIRONMENT' no existe en $ISTIO_DIR"
    exit 1
fi

# Validar que el archivo terraform.tfvars existe
if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Error: No se encontró $TFVARS_FILE"
    exit 1
fi

echo "🔍 Buscando clusters activos para ambiente: $ENVIRONMENT"

# Obtener clusters activos
CLUSTERS=$(oci ce cluster list --compartment-id "$COMPARTMENT_ID" --query "data[?\"lifecycle-state\"=='ACTIVE'].{id:id,name:name}" --output json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Error: No se pudo conectar a OCI. Verifica que OCI CLI esté configurado."
    exit 1
fi

# Mostrar clusters disponibles
# Contar clusters disponibles
CLUSTER_COUNT=$(echo "$CLUSTERS" | jq length)

if [ "$CLUSTER_COUNT" -eq 0 ]; then
    echo "❌ Error: No se encontraron clusters activos"
    exit 1
elif [ "$CLUSTER_COUNT" -eq 1 ]; then
    # Solo un cluster disponible
    CLUSTER_ID=$(echo "$CLUSTERS" | jq -r '.[0].id')
    CLUSTER_NAME=$(echo "$CLUSTERS" | jq -r '.[0].name')
    echo "✅ Único cluster encontrado: $CLUSTER_NAME"
else
    # Múltiples clusters - mostrar menú de selección
    echo "📋 Clusters activos encontrados:"
    
    # Crear array para almacenar clusters
    declare -a CLUSTER_ARRAY
    i=1
    
    while IFS= read -r line; do
        CLUSTER_ARRAY[i]="$line"
        NAME=$(echo "$line" | jq -r '.name')
        ID=$(echo "$line" | jq -r '.id')
        echo "  [$i] $NAME"
        echo "      ID: $ID"
        ((i++))
    done < <(echo "$CLUSTERS" | jq -c '.[]')
    
    echo ""
    read -p "Selecciona el cluster (1-$((i-1))): " SELECTION
    
    # Validar selección
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -ge "$i" ]; then
        echo "❌ Error: Selección inválida"
        exit 1
    fi
    
    # Obtener cluster seleccionado
    SELECTED_CLUSTER="${CLUSTER_ARRAY[$SELECTION]}"
    CLUSTER_ID=$(echo "$SELECTED_CLUSTER" | jq -r '.id')
    CLUSTER_NAME=$(echo "$SELECTED_CLUSTER" | jq -r '.name')
    
    echo "✅ Cluster seleccionado: $CLUSTER_NAME"
fi

echo "✅ Usando cluster ID: $CLUSTER_ID"

# Crear backup del archivo original
cp "$TFVARS_FILE" "$TFVARS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "💾 Backup creado: $TFVARS_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Actualizar cluster_id en terraform.tfvars
if grep -q "cluster_id.*=" "$TFVARS_FILE"; then
    # Reemplazar línea existente
    sed -i.tmp "s|cluster_id.*=.*|cluster_id = \"$CLUSTER_ID\"|" "$TFVARS_FILE"
    rm -f "$TFVARS_FILE.tmp"
    echo "🔄 cluster_id actualizado en $TFVARS_FILE"
else
    echo "❌ Error: No se encontró la variable cluster_id en $TFVARS_FILE"
    exit 1
fi

# Verificar el cambio
echo "✅ Verificación:"
grep "cluster_id" "$TFVARS_FILE"

echo ""
echo "🎉 ¡Actualización completada!"
echo "📁 Archivo actualizado: $TFVARS_FILE"
echo "🚀 Ahora puedes ejecutar terraform plan/apply en $ISTIO_DIR"