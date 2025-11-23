terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = var.istio_version
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = var.istio_version
  timeout    = 600
  
  set {
    name  = "pilot.resources.requests.memory"
    value = "128Mi"
  }
  
  set {
    name  = "pilot.resources.requests.cpu"
    value = "100m"
  }
  
  values     = var.istiod_values != "" ? [var.istiod_values] : []
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  version    = var.istio_version
  timeout    = 600  # 10 minutos
  wait       = false  # No esperar LoadBalancer IP
  
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  
  values     = var.ingress_values != "" ? [var.ingress_values] : []
  depends_on = [helm_release.istiod]
}

# Verificar que los CRDs de Istio estén disponibles
resource "null_resource" "wait_for_istio_crds" {
  depends_on = [helm_release.istiod]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Esperando CRDs de Istio..."
      for i in {1..30}; do
        if kubectl get crd gateways.networking.istio.io peerauthentications.security.istio.io virtualservices.networking.istio.io >/dev/null 2>&1; then
          echo "CRDs de Istio disponibles"
          exit 0
        fi
        echo "Intento $i/30: CRDs no disponibles, esperando..."
        sleep 10
      done
      echo "Error: CRDs de Istio no disponibles después de 5 minutos"
      exit 1
    EOT
  }
}

resource "kubernetes_manifest" "istio_gateway" {
  count = var.enable_gateway ? 1 : 0
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = var.gateway_name
      namespace = var.gateway_namespace
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = concat(
        [
          {
            port = {
              number   = 80
              name     = "http"
              protocol = "HTTP"
            }
            hosts = var.gateway_hosts
            tls = {
              httpsRedirect = var.enable_https_redirect
            }
          }
        ],
        var.enable_tls ? [
          {
            port = {
              number   = 443
              name     = "https"
              protocol = "HTTPS"
            }
            hosts = var.gateway_hosts
            tls = {
              mode           = "SIMPLE"
              credentialName = var.tls_secret_name
            }
          }
        ] : []
      )
    }
  }
  
  depends_on = [helm_release.istio_ingress, null_resource.wait_for_istio_crds]
}

resource "kubernetes_manifest" "istio_virtualservice" {
  count = var.enable_gateway ? 1 : 0
  
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = var.virtualservice_name
      namespace = var.virtualservice_namespace
    }
    spec = {
      hosts    = var.virtualservice_hosts
      gateways = [var.gateway_name]
      http = [
        {
          route = [
            {
              destination = {
                host = var.virtualservice_destination_host
                port = {
                  number = var.virtualservice_destination_port
                }
              }
            }
          ]
        }
      ]
    }
  }
  
  depends_on = [kubernetes_manifest.istio_gateway, null_resource.wait_for_istio_crds]
}

resource "kubernetes_manifest" "peer_authentication" {
  count = var.enable_gateway ? 1 : 0
  
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = "istio-system"
    }
    spec = {
      mtls = {
        mode = var.mtls_mode
      }
    }
  }
  
  depends_on = [helm_release.istiod, null_resource.wait_for_istio_crds]
}