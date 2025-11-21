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
  values     = var.istiod_values != "" ? [var.istiod_values] : []
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"
  version    = var.istio_version
  
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  
  values     = var.ingress_values != "" ? [var.ingress_values] : []
  depends_on = [helm_release.istiod]
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
  
  depends_on = [helm_release.istio_ingress]
}

resource "kubernetes_manifest" "istio_virtualservice" {
  count = var.enable_virtualservice ? 1 : 0
  
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
  
  depends_on = [kubernetes_manifest.istio_gateway]
}

resource "kubernetes_manifest" "peer_authentication" {
  count = var.enable_peer_authentication ? 1 : 0
  
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
  
  depends_on = [helm_release.istiod]
}