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
  cluster_id = module.k8s_cluster.cluster_id
}

provider "kubernetes" {
  host                   = yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", module.k8s_cluster.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["server"]
    cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.cluster.content)["clusters"][0]["cluster"]["certificate-authority-data"])
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "oci"
      args        = ["ce", "cluster", "generate-token", "--cluster-id", module.k8s_cluster.cluster_id]
    }
  }
}

module "networking" {
  source = "../../../modules/oci/networking"

  compartment_id  = var.compartment_id
  vcn_name        = var.vcn_name
  vcn_cidr_blocks = var.vcn_cidr_blocks
  dns_label       = var.dns_label
  subnets         = var.subnets
}

module "k8s_cluster" {
  source = "../../../modules/oci/k8s-cluster"

  compartment_id          = var.compartment_id
  cluster_name            = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  vcn_id                  = module.networking.vcn_id
  control_plane_subnet_id = module.networking.subnet_ids["control-plane"]
  node_subnet_id          = module.networking.subnet_ids["nodes"]
  service_lb_subnet_ids   = [module.networking.subnet_ids["lb"]]
  is_public_endpoint      = var.is_public_endpoint
  cluster_type            = var.cluster_type
  availability_domain     = var.availability_domain
  node_image_id           = var.node_image_id
  node_pools              = var.node_pools
}

module "database" {
  source = "../../../modules/oci/database"

  compartment_id = var.compartment_id
  db_name        = var.db_name
  display_name   = var.db_system_name
  admin_password = var.db_admin_password
  db_version     = "19c"
  is_free_tier   = true
  
  # FREE TIER - Commented out unsupported parameters
  # subnet_id                 = module.networking.subnet_ids["db"]
  # cpu_core_count            = 1
  # data_storage_size_in_tbs  = 1
  # backup_enabled            = var.db_backup_enabled
}

module "ocir" {
  source          = "../../../modules/oci/ocir"
  compartment_id  = var.compartment_id
  repository_name = var.ocir_repository_name
  is_public       = false
  tenancy_ocid = var.tenancy_ocid
}

module "load_balancer" {
  source         = "../../../modules/oci/load-balancer"
  compartment_id = var.compartment_id
  display_name   = var.lb_display_name
  shape          = var.lb_shape
  subnet_ids     = [module.networking.subnet_ids["lb"]]
  is_private     = false
}

module "dns" {
  source         = "../../../modules/oci/dns"
  compartment_id = var.compartment_id
  zone_name      = var.dns_zone_name
  zone_type      = "PRIMARY"
}

module "vault" {
  source         = "../../../modules/oci/secrets"
  compartment_id = var.compartment_id
  vault_name     = var.vault_name
  vault_type     = "DEFAULT"
}

module "iam" {
  source         = "../../../modules/oci/iam"
  compartment_id = var.compartment_id
  policy_name    = var.iam_policy_name
  tenancy_ocid   = var.tenancy_ocid
}

module "waf" {
  source          = "../../../modules/oci/waf"
  compartment_id  = var.compartment_id
  waf_policy_name = var.waf_policy_name
  waf_enabled     = false
}

module "monitoring" {
  source              = "../../../modules/oci/monitoring"
  compartment_id      = var.compartment_id
  namespace           = var.monitoring_namespace
  alarm_enabled       = var.monitoring_alarm_enabled
  lb_id               = module.load_balancer.load_balancer_id
  waf_policy_id       = module.waf.waf_policy_id
  db_id               = module.database.database_id
  enable_lb_logging   = true
  enable_waf_logging  = false
  enable_db_logging   = true
  alarm_destinations  = []
}

# Istio Service Mesh se despliega por separado
# Ver: environments/oci/dev/istio/
