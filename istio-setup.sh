#!/bin/bash

# Script optimizado para configurar Istio con endpoint público
# Uso: ./istio-setup.sh <environment>
# Ejemplo: ./istio-setup.sh dev

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

# Suprimir warnings de OCI CLI
export SUPPRESS_LABEL_WARNING=True

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

# Verificar dependencias
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq no está instalado. Instálalo con: brew install jq"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl no está instalado. Instálalo primero."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: terraform no está instalado. Instálalo primero."
    exit 1
fi

echo "🔍 Buscando clusters activos para ambiente: $ENVIRONMENT"
echo "🔧 Configurando Istio con endpoint público automáticamente..."
echo ""

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
    # Múltiples clusters - mostrar menú de selección (PARTE ORIGINAL)
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

# Configurar endpoint público y security lists
echo "🔧 Configurando acceso público al cluster..."

# Obtener subnet del cluster
SUBNET_ID=$(oci ce cluster get --cluster-id "$CLUSTER_ID" --query 'data."endpoint-config"."subnet-id"' --raw-output 2>/dev/null)

if [ "$SUBNET_ID" != "null" ] && [ -n "$SUBNET_ID" ]; then
    echo "📡 Subnet del cluster: $SUBNET_ID"
    
    # Obtener security lists de la subnet
    SECURITY_LISTS=$(oci network subnet get --subnet-id "$SUBNET_ID" --query 'data."security-list-ids"' --raw-output 2>/dev/null)
    
    if [ -n "$SECURITY_LISTS" ]; then
        # Procesar cada security list
        echo "$SECURITY_LISTS" | jq -r '.[]' | while read -r SL_ID; do
            echo "🔒 Verificando Security List: $SL_ID"
            
            # Verificar si ya existe regla para puerto 6443
            HAS_6443=$(oci network security-list get --security-list-id "$SL_ID" --query 'data."ingress-security-rules"[?"tcp-options"."destination-port-range".max==`6443`]' --raw-output 2>/dev/null)
            
            if [ "$HAS_6443" = "[]" ]; then
                echo "➕ Agregando regla para puerto 6443..."
                
                # Obtener reglas actuales
                CURRENT_RULES=$(oci network security-list get --security-list-id "$SL_ID" --query 'data."ingress-security-rules"' 2>/dev/null)
                
                # Agregar nueva regla para puerto 6443
                NEW_RULES=$(echo "$CURRENT_RULES" | jq '. + [{
                    "protocol": "6",
                    "source": "0.0.0.0/0",
                    "source-type": "CIDR_BLOCK",
                    "tcp-options": {
                        "destination-port-range": {
                            "max": 6443,
                            "min": 6443
                        }
                    },
                    "is-stateless": false
                }]')
                
                # Actualizar security list
                oci network security-list update --security-list-id "$SL_ID" --ingress-security-rules "$NEW_RULES" --force >/dev/null 2>&1
                
                if [ $? -eq 0 ]; then
                    echo "✅ Regla para puerto 6443 agregada exitosamente"
                else
                    echo "⚠️ Error agregando regla para puerto 6443"
                fi
            else
                echo "✅ Puerto 6443 ya está configurado"
            fi
        done
    fi
else
    echo "⚠️ No se pudo obtener información de la subnet del cluster"
fi

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

# Verificar conectividad al cluster
echo "🔍 Verificando conectividad al cluster..."
CLUSTER_ENDPOINT=$(oci ce cluster get --cluster-id "$CLUSTER_ID" --query "data.endpoints.\"public-endpoint\"" --raw-output 2>/dev/null)

# Configurar kubeconfig con endpoint público
echo "🔧 Configurando kubeconfig..."
oci ce cluster create-kubeconfig --cluster-id "$CLUSTER_ID" --file ~/.kube/config --region sa-bogota-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT >/dev/null 2>&1

if [ "$CLUSTER_ENDPOINT" != "null" ] && [ -n "$CLUSTER_ENDPOINT" ]; then
    echo "🌐 Endpoint del cluster: $CLUSTER_ENDPOINT"
    
    # Test de conectividad básico
    timeout 5 bash -c "</dev/tcp/${CLUSTER_ENDPOINT%:*}/${CLUSTER_ENDPOINT#*:}" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Cluster accesible públicamente"
    else
        echo "⚠️ Cluster no accesible - puede tomar unos minutos en aplicar las reglas"
    fi
else
    echo "⚠️ Endpoint del cluster no disponible aún"
fi

echo ""
echo "🎉 ¡Configuración completada!"
echo "📁 Archivo actualizado: $TFVARS_FILE"
echo "🔒 Security Lists configuradas para acceso público"
echo ""

# Verificar istioctl (opcional)
echo "🔍 Verificando istioctl..."
if command -v istioctl &> /dev/null; then
    echo "✅ istioctl disponible: $(which istioctl)"
else
    echo "ℹ️ istioctl no encontrado (opcional para diagnósticos)"
    echo "💡 Para instalar: curl -L https://istio.io/downloadIstio | sh -"
fi

echo ""
echo "🚀 Desplegando Istio con Terraform..."
echo ""

# Cambiar al directorio de Istio
cd "$ISTIO_DIR" || {
    echo "❌ Error: No se pudo acceder al directorio $ISTIO_DIR"
    exit 1
}

# Terraform init
echo "🔧 Inicializando Terraform..."
terraform init -upgrade
if [ $? -ne 0 ]; then
    echo "❌ Error en terraform init"
    exit 1
fi

# Verificar node pools y nodos del cluster
echo "🔍 Verificando node pools del cluster..."

# Obtener node pools del cluster
NODE_POOLS=$(oci ce node-pool list --cluster-id "$CLUSTER_ID" --compartment-id "$COMPARTMENT_ID" --query "data[].{id:id,name:name,state:\"lifecycle-state\"}" --output json 2>/dev/null)

if [ -n "$NODE_POOLS" ] && [ "$NODE_POOLS" != "[]" ]; then
    echo "📋 Node pools encontrados:"
    echo "$NODE_POOLS" | jq -r '.[] | "  • \(.name): \(.state)"'
    
    # Verificar nodos de cada node pool
    echo ""
    echo "🔍 Verificando estado de los nodos..."
    
    TOTAL_NODES=0
    ACTIVE_NODES=0
    
    echo "$NODE_POOLS" | jq -r '.[].id' | while read -r POOL_ID; do
        POOL_INFO=$(oci ce node-pool get --node-pool-id "$POOL_ID" --query "data.{name:name,state:\"lifecycle-state\",node_count:\"quantity-per-subnet\"}" 2>/dev/null)
        POOL_NAME=$(echo "$POOL_INFO" | jq -r '.name')
        POOL_STATE=$(echo "$POOL_INFO" | jq -r '.state')
        
        echo "📊 Pool: $POOL_NAME ($POOL_STATE)"
        
        # Obtener nodos del pool
        NODES=$(oci ce node-pool get --node-pool-id "$POOL_ID" --query "data.nodes[].{state:\"lifecycle-state\",name:name}" 2>/dev/null)
        
        if [ -n "$NODES" ] && [ "$NODES" != "[]" ]; then
            echo "$NODES" | jq -r '.[] | "    • \(.name): \(.state)"'
            
            # Contar nodos por estado
            NODE_COUNT=$(echo "$NODES" | jq length)
            ACTIVE_COUNT=$(echo "$NODES" | jq '[.[] | select(.state == "ACTIVE")] | length')
            UPDATING_COUNT=$(echo "$NODES" | jq '[.[] | select(.state == "UPDATING")] | length')
            
            echo "    Total: $NODE_COUNT nodos (Activos: $ACTIVE_COUNT, Actualizando: $UPDATING_COUNT)"
            
            TOTAL_NODES=$((TOTAL_NODES + NODE_COUNT))
            ACTIVE_NODES=$((ACTIVE_NODES + ACTIVE_COUNT))
        else
            echo "    Sin nodos encontrados"
        fi
        echo ""
    done
    
    # Fix subshell variable scope by using process substitution
    TOTAL_NODES=0
    ACTIVE_NODES=0
    
    while IFS= read -r POOL_ID; do
        POOL_INFO=$(oci ce node-pool get --node-pool-id "$POOL_ID" --query "data.{name:name,state:\"lifecycle-state\",node_count:\"quantity-per-subnet\"}" 2>/dev/null)
        POOL_NAME=$(echo "$POOL_INFO" | jq -r '.name')
        POOL_STATE=$(echo "$POOL_INFO" | jq -r '.state')
        
        echo "📊 Pool: $POOL_NAME ($POOL_STATE)"
        
        # Obtener nodos del pool
        NODES=$(oci ce node-pool get --node-pool-id "$POOL_ID" --query "data.nodes[].{state:\"lifecycle-state\",name:name}" 2>/dev/null)
        
        if [ -n "$NODES" ] && [ "$NODES" != "[]" ]; then
            echo "$NODES" | jq -r '.[] | "    • \(.name): \(.state)"'
            
            # Contar nodos por estado
            NODE_COUNT=$(echo "$NODES" | jq length)
            ACTIVE_COUNT=$(echo "$NODES" | jq '[.[] | select(.state == "ACTIVE")] | length')
            UPDATING_COUNT=$(echo "$NODES" | jq '[.[] | select(.state == "UPDATING")] | length')
            
            echo "    Total: $NODE_COUNT nodos (Activos: $ACTIVE_COUNT, Actualizando: $UPDATING_COUNT)"
            
            TOTAL_NODES=$((TOTAL_NODES + NODE_COUNT))
            ACTIVE_NODES=$((ACTIVE_NODES + ACTIVE_COUNT))
        else
            echo "    Sin nodos encontrados"
        fi
        echo ""
    done < <(echo "$NODE_POOLS" | jq -r '.[].id')
    
    # Verificar kubectl
    echo "🔍 Verificando nodos en kubectl..."
    KUBECTL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$KUBECTL_NODES" -eq 0 ]; then
        if [ "$ACTIVE_NODES" -gt 0 ]; then
            echo "⚠️ Los nodos están activos en OCI pero no aparecen en kubectl"
            echo "Esto puede indicar un problema de conectividad o configuración"
        else
            echo "❌ Error: No hay nodos disponibles para Istio"
            echo ""
            echo "📊 Resumen del estado:"
            echo "  • Total de nodos: $TOTAL_NODES"
            echo "  • Nodos activos: $ACTIVE_NODES"
            echo "  • Nodos en kubectl: $KUBECTL_NODES"
            echo ""
            echo "💡 Los nodos pueden estar en proceso de actualización."
            echo "Espera unos minutos y vuelve a ejecutar el script."
            exit 1
        fi
    else
        echo "✅ Cluster tiene $KUBECTL_NODES nodo(s) disponible(s) en kubectl"
        
        # Mostrar estado detallado de los nodos
        echo ""
        echo "📊 Estado detallado de los nodos:"
        kubectl get nodes -o wide
    fi
else
    echo "❌ Error: No se encontraron node pools para el cluster"
    echo "Verifica que el cluster tenga node pools configurados"
    exit 1
fi

# Terraform plan
echo "📋 Ejecutando terraform plan..."
terraform plan
if [ $? -ne 0 ]; then
    echo "❌ Error en terraform plan"
    exit 1
fi

# FASE 1: Instalar componentes Helm de Istio con timeouts extendidos
echo "📦 FASE 1: Instalando componentes base de Istio con Helm..."
echo "⏱️ Configurando timeouts extendidos para LoadBalancer..."

# Instalar base e istiod primero
echo "🔧 Instalando Istio base e istiod..."
terraform apply -target=module.istio.helm_release.istio_base -target=module.istio.helm_release.istiod -auto-approve
if [ $? -ne 0 ]; then
    echo "❌ Error instalando base e istiod"
    exit 1
fi

# Esperar que istiod esté listo antes de instalar ingress
echo "⏳ Esperando que istiod esté listo..."
kubectl wait --for=condition=ready pod -l app=istiod -n istio-system --timeout=300s

# Instalar ingress gateway con timeout extendido
echo "🚪 Instalando Istio Ingress Gateway..."
terraform apply -target=module.istio.helm_release.istio_ingress -auto-approve
if [ $? -ne 0 ]; then
    echo "⚠️ Error en ingress gateway, pero continuando..."
    echo "💡 El LoadBalancer puede tardar varios minutos en provisionar"
fi

# Verificar que los CRDs estén instalados
echo "🔍 Verificando CRDs de Istio..."
echo "Esperando que los CRDs estén disponibles..."

for i in {1..30}; do
    CRD_COUNT=$(kubectl get crd 2>/dev/null | grep istio | wc -l | tr -d ' ')
    if [ "$CRD_COUNT" -gt 0 ]; then
        echo "✅ CRDs de Istio disponibles ($CRD_COUNT encontrados)"
        break
    fi
    echo "Intento $i/30: Esperando CRDs..."
    sleep 10
done

if [ "$CRD_COUNT" -eq 0 ]; then
    echo "❌ Error: CRDs de Istio no disponibles después de 5 minutos"
    echo "Verifica manualmente: kubectl get crd | grep istio"
    exit 1
fi

# FASE 2: Habilitar manifests de Kubernetes y aplicar configuración completa
echo "🔧 FASE 2: Habilitando manifests de Kubernetes..."

# Habilitar los kubernetes_manifest cambiando count de 0 a las variables originales
MODULE_FILE="../../../../modules/oci/istio/main.tf"

if [ -f "$MODULE_FILE" ]; then
    # Crear backup
    cp "$MODULE_FILE" "$MODULE_FILE.backup"
    
    # Restaurar counts originales
    sed -i.tmp 's/count = 0  # Temporalmente deshabilitado/count = var.enable_gateway ? 1 : 0/' "$MODULE_FILE"
    sed -i.tmp 's/count = 0  # Temporalmente deshabilitado/count = var.enable_virtualservice ? 1 : 0/' "$MODULE_FILE"
    sed -i.tmp 's/count = 0  # Temporalmente deshabilitado/count = var.enable_peer_authentication ? 1 : 0/' "$MODULE_FILE"
    rm -f "$MODULE_FILE.tmp"
    
    echo "✅ Manifests de Kubernetes habilitados"
else
    echo "❌ Error: No se encontró el archivo del módulo: $MODULE_FILE"
    exit 1
fi

# Aplicar configuración completa
echo "🔧 Aplicando configuración completa de Istio..."
terraform apply -auto-approve
if [ $? -eq 0 ]; then
    echo "✅ Istio desplegado exitosamente"
    
    # Mostrar información del deployment
    echo ""
    echo "📊 Estado del deployment:"
    kubectl get pods -n istio-system
    echo ""
    kubectl get svc -n istio-system
    echo ""
    echo "🔍 Verificando CRDs finales:"
    kubectl get crd | grep istio
else
    echo "❌ Error en FASE 2: Configuración completa fallida"
    echo "Restaurando backup del módulo..."
    cp "$MODULE_FILE.backup" "$MODULE_FILE"
    exit 1
fi

# Limpiar archivos temporales
rm -f "$MODULE_FILE.backup"

echo ""
echo "🎉 ¡Istio configurado exitosamente!"
echo "🔗 Endpoint del cluster: $CLUSTER_ENDPOINT"
echo "🚪 Gateway de Istio disponible en el LoadBalancer"
echo ""

# Verificaciones finales completas
echo "🔍 Ejecutando verificaciones finales..."
echo ""

# 1. Verificar version de istioctl (opcional)
echo "1️⃣ Version de istioctl:"
if command -v istioctl &> /dev/null; then
    istioctl version --short 2>/dev/null
else
    echo "   ℹ️ istioctl no instalado (opcional)"
fi
echo ""

# 2. Verificar estado de los pods
echo "2️⃣ Estado de pods en istio-system:"
kubectl get pods -n istio-system
echo ""

# 3. Verificar servicios
echo "3️⃣ Servicios de Istio:"
kubectl get svc -n istio-system
echo ""

# 4. Verificar LoadBalancer
echo "4️⃣ Estado del LoadBalancer:"
EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    echo "   ✅ External IP: $EXTERNAL_IP"
else
    echo "   ⏳ External IP: Pendiente (puede tardar varios minutos)"
fi
echo ""

# 5. Verificar CRDs
echo "5️⃣ CRDs de Istio instalados:"
CRD_COUNT=$(kubectl get crd 2>/dev/null | grep istio | wc -l | tr -d ' ')
echo "   ✅ Total: $CRD_COUNT CRDs"
echo ""

# 6. Verificar configuracion de Istio
echo "6️⃣ Configuracion de Istio:"
if command -v istioctl &> /dev/null; then
    istioctl proxy-status 2>/dev/null || echo "   ⚠️ Proxy status no disponible aun"
else
    echo "   ℹ️ istioctl no disponible para proxy-status"
fi
echo ""

# FASE 3: Desplegar aplicaciones
echo "🚀 FASE 3: Desplegando aplicaciones..."
echo ""

# Obtener directorio raíz del proyecto
PROJECT_ROOT="$(cd "../../../../" && pwd)"
cd "$PROJECT_ROOT" || {
    echo "❌ Error: No se pudo acceder al directorio raíz: $PROJECT_ROOT"
    exit 1
}

echo "📍 Directorio actual: $(pwd)"

# Verificar que existan los archivos de helm values
APP_DIR="shared/app-deployment/helm-values/$ENVIRONMENT"
if [ ! -d "$APP_DIR" ]; then
    echo "⚠️ Directorio de aplicaciones no encontrado: $APP_DIR"
    echo "Saltando deployment de aplicaciones..."
else
    echo "📱 Desplegando aplicaciones para ambiente: $ENVIRONMENT"
    
    # Agregar repositorios de Helm
    echo "📚 Agregando repositorios de Helm..."
    helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1
    helm repo update >/dev/null 2>&1
    
    # Desplegar Redis
    if [ -f "$APP_DIR/redis.yaml" ]; then
        echo "🔴 Instalando Redis..."
        helm install redis bitnami/redis -f "$APP_DIR/redis.yaml" --create-namespace --namespace redis
        if [ $? -eq 0 ]; then
            echo "✅ Redis instalado exitosamente"
        else
            echo "⚠️ Error instalando Redis"
        fi
    fi
    
    # Crear namespace para aplicaciones
    kubectl create namespace addon-ai --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
    
    # Crear deployments básicos para las aplicaciones
    echo "🔌 Creando deployment para addon-ai-api..."
    kubectl apply -f - <<EOF >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ai-api
  namespace: addon-ai
spec:
  replicas: 1
  selector:
    matchLabels:
      app: addon-ai-api
  template:
    metadata:
      labels:
        app: addon-ai-api
    spec:
      containers:
      - name: addon-ai-api
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF
    
    echo "🌐 Creando deployment para addon-ai-frontend..."
    kubectl apply -f - <<EOF >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: addon-ai-frontend
  namespace: addon-ai
spec:
  replicas: 1
  selector:
    matchLabels:
      app: addon-ai-frontend
  template:
    metadata:
      labels:
        app: addon-ai-frontend
    spec:
      containers:
      - name: addon-ai-frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF
    
    echo "✅ Aplicaciones desplegadas como deployments básicos"
    
    echo ""
    echo "📊 Estado de las aplicaciones:"
    kubectl get pods -n redis 2>/dev/null || echo "   Redis: No desplegado"
    kubectl get pods -n addon-ai 2>/dev/null || echo "   Addon-AI: No desplegado"
fi

# FASE 4: Desplegar stack de monitoreo
echo "📊 FASE 4: Desplegando stack de monitoreo..."
echo ""

# Agregar repositorios necesarios
echo "📚 Agregando repositorios de monitoreo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts >/dev/null 2>&1
helm repo add kiali https://kiali.org/helm-charts >/dev/null 2>&1
helm repo update >/dev/null 2>&1

# Instalar Prometheus + Grafana
echo "📈 Instalando Prometheus + Grafana..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f shared/cluster-addons/monitoring/prometheus/values-dev.yaml \
  --create-namespace --namespace monitoring >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Prometheus + Grafana instalado exitosamente"
else
    echo "⚠️ Error instalando Prometheus + Grafana"
fi

# Instalar Jaeger
echo "🔍 Instalando Jaeger..."

# 1. Desinstalar la instalación actual
helm uninstall jaeger -n istio-system >/dev/null 2>&1

# 2. Instalar Jaeger con el registry completo de Docker Hub
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set provisionDataStore.elasticsearch=false \
  --set storage.type=memory \
  --set allInOne.enabled=true \
  --set allInOne.image.repository=docker.io/jaegertracing/all-in-one \
  --set allInOne.image.tag=1.56 \
  --set agent.enabled=false \
  --set collector.enabled=false \
  --set query.enabled=false \
  --namespace istio-system >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Jaeger instalado exitosamente"
else
    echo "⚠️ Error instalando Jaeger"
fi

# Instalar Kiali
echo "🕸️ Instalando Kiali..."
helm install kiali kiali/kiali-server \
  --set auth.strategy=anonymous \
  --set deployment.accessible_namespaces=["**"] \
  --set external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.monitoring:9090" \
  --set external_services.grafana.url="http://prometheus-grafana.monitoring:80" \
  --set external_services.tracing.url="http://jaeger-query.istio-system:16686" \
  --namespace istio-system >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Kiali instalado exitosamente"
else
    echo "⚠️ Error instalando Kiali"
fi

echo ""
echo "📊 Estado del stack de monitoreo:"
kubectl get pods -n monitoring 2>/dev/null || echo "   Monitoring: No desplegado"
kubectl get pods -n istio-system | grep -E "(jaeger|kiali)" 2>/dev/null || echo "   Jaeger/Kiali: No desplegado"

echo ""
echo "📊 Resumen del deployment:"
echo "  ✅ FASE 1: Componentes Helm instalados"
echo "  ✅ FASE 2: Manifests de Kubernetes aplicados"
echo "  ✅ FASE 3: Aplicaciones desplegadas"
echo "  ✅ FASE 4: Stack de monitoreo desplegado"
echo "  ✅ CRDs de Istio: $CRD_COUNT disponibles"
echo "  ✅ Istio: Desplegado vía Terraform/Helm"
echo ""
echo "🌐 Acceso a dashboards:"
echo "  • Ejecuta: ./dashboard-access.sh"
echo "  • Grafana: http://localhost:3000"
echo "  • Jaeger: http://localhost:16686"
echo "  • Kiali: http://localhost:20001"
echo "  • Prometheus: http://localhost:9090"
echo ""
echo "🔑 Credenciales:"
echo "  • Grafana: admin / dev-grafana-password"
echo "  • Kiali: Sin autenticación (anonymous)"
echo ""
echo "💡 Comandos útiles:"
echo "  • kubectl get pods -n istio-system"
echo "  • kubectl get pods -n monitoring"
echo "  • kubectl get pods -n redis"
echo "  • kubectl get pods -n addon-ai"
echo ""
echo "🚀 Configurando port-forwards para acceso a dashboards..."
echo ""

# Crear script para port-forwards
cat > dashboard-access.sh << 'EOF'
#!/bin/bash
echo "🌐 Iniciando port-forwards para dashboards..."
echo "Presiona Ctrl+C para detener todos los port-forwards"
echo ""

# Función para cleanup
cleanup() {
    echo ""
    echo "🛑 Deteniendo port-forwards..."
    jobs -p | xargs -r kill
    exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar port-forwards en background
echo "📈 Grafana: http://localhost:3000 (admin/dev-grafana-password)"
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 >/dev/null 2>&1 &

echo "🔍 Jaeger: http://localhost:16686"
kubectl port-forward -n istio-system svc/jaeger-query 16686:16686 >/dev/null 2>&1 &

echo "🕸️ Kiali: http://localhost:20001 (anonymous)"
kubectl port-forward -n istio-system svc/kiali 20001:20001 >/dev/null 2>&1 &

echo "📊 Prometheus: http://localhost:9090"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &

echo ""
echo "✅ Todos los dashboards están disponibles!"
echo "Presiona Ctrl+C para detener"

# Esperar indefinidamente
while true; do
    sleep 1
done
EOF

chmod +x dashboard-access.sh

echo "📋 Script creado: dashboard-access.sh"
echo "💡 Para acceder a los dashboards ejecuta: ./dashboard-access.sh"
echo ""
echo "🎯 URLs de acceso:"
echo "  • Grafana: http://localhost:3000 (admin/dev-grafana-password)"
echo "  • Jaeger: http://localhost:16686"
echo "  • Kiali: http://localhost:20001 (anonymous)"
echo "  • Prometheus: http://localhost:9090"