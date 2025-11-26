# OCI Authentication - Values replaced by CI/CD from GitHub Secrets
tenancy_ocid   = "__TENANCY_OCID__"
user_ocid      = "__USER_OCID__"
fingerprint    = "__FINGERPRINT__"
private_key    = "__PRIVATE_KEY__"
region         = "sa-bogota-1"
compartment_id = "__COMPARTMENT_ID__"

# Networking
vcn_name        = "addon-ai-dev-vcn"
vcn_cidr_blocks = ["10.0.0.0/16"]
dns_label       = "addonaidev"

subnets = {
  "control-plane" = {
    name      = "addon-ai-dev-control-plane"
    cidr      = "10.0.1.0/24"
    dns_label = "controlplane"
    private   = false
  }
  "nodes" = {
    name      = "addon-ai-dev-nodes"
    cidr      = "10.0.2.0/24"
    dns_label = "nodes"
    private   = true
  }
  "lb" = {
    name      = "addon-ai-dev-lb"
    cidr      = "10.0.3.0/24"
    dns_label = "lb"
    private   = false
  }
  "db" = {
    name      = "addon-ai-dev-db"
    cidr      = "10.0.4.0/24"
    dns_label = "db"
    private   = true
  }
}

# OKE Cluster - Basic Cluster (Free Tier)
cluster_name        = "addon-ai-dev-oke"
kubernetes_version  = "v1.34.1"
cluster_type        = "BASIC_CLUSTER"
is_public_endpoint  = true
availability_domain = "WBkQ:SA-BOGOTA-1-AD-1"
node_image_id       = "ocid1.image.oc1.sa-bogota-1.aaaaaaaalcrfyhysejbsevr32jppcn6vyicrl53f6zofplpieffqvstxluuq"

# Node Pools - E4 Flex (AMD - Always Available)
node_pools = {
  "default" = {
    name      = "addon-ai-dev-pool"
    shape     = "VM.Standard3.Flex"
    ocpus     = 1
    memory_gb = 16
    size      = 1
  }
}

# PostgreSQL Database - Free Tier
db_system_name    = "addon-ai-dev-postgres"
db_admin_password = "__DB_ADMIN_PASSWORD__"
db_name           = "addonaidevdbash2"
db_backup_enabled = true

# OCIR (Container Registry)
ocir_repository_name = "addon-ai-dev-repo"

# Load Balancer
lb_display_name = "addon-ai-dev-lb"
lb_shape        = "flexible"
# enable_https    = false  # Variable no definida en el módulo

# DNS
dns_zone_name = "dev.addon-ai.com"

# IAM
iam_policy_name = "addon-ai-dev-policy-bog"

# Vault
vault_name = "addon-ai-dev-vault"

# WAF
waf_policy_name = "addon-ai-dev-waf"

# Monitoring
monitoring_namespace = "addon-ai-dev-monitoring-ash"
monitoring_alarm_enabled = false

# Vault

# WAF