terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
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

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}

data "oci_containerengine_cluster_kube_config" "cluster" {
  cluster_id = var.cluster_id
}

provider "kubernetes" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", var.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["server"]
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["certificate-authority-data"])
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "oci"
      args        = ["ce", "cluster", "generate-token", "--cluster-id", var.cluster_id]
    }
  }
}

module "istio" {
  source = "../../../../modules/oci/istio"

  istio_version                    = var.istio_version
  istiod_values                    = var.istiod_values
  ingress_values                   = var.ingress_values
  enable_gateway                   = var.enable_gateway
  gateway_name                     = var.gateway_name
  gateway_namespace                = var.gateway_namespace
  gateway_hosts                    = var.gateway_hosts
  enable_virtualservice            = var.enable_virtualservice
  virtualservice_name              = var.virtualservice_name
  virtualservice_namespace         = var.virtualservice_namespace
  virtualservice_hosts             = var.virtualservice_hosts
  virtualservice_destination_host  = var.virtualservice_destination_host
  virtualservice_destination_port  = var.virtualservice_destination_port
  enable_peer_authentication       = var.enable_peer_authentication
  mtls_mode                        = var.mtls_mode
  enable_tls                       = var.enable_tls
  enable_https_redirect            = var.enable_https_redirect
  tls_secret_name                  = var.tls_secret_name
}