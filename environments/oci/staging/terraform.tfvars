# OCI Authentication - Values replaced by CI/CD from GitHub Secrets
tenancy_ocid   = "__TENANCY_OCID__"
user_ocid      = "__USER_OCID__"
fingerprint    = "__FINGERPRINT__"
private_key    = "__PRIVATE_KEY__"
region         = "sa-bogota-1"
compartment_id = "__COMPARTMENT_ID__"

# Networking
vcn_name        = "addon-ai-staging-vcn"
vcn_cidr_blocks = ["10.2.0.0/16"]
dns_label       = "addonaistaging"

subnets = {
  "control-plane" = {
    name      = "addon-ai-staging-control-plane"
    cidr      = "10.2.1.0/24"
    dns_label = "controlplane"
    private   = true
  }
  "nodes" = {
    name      = "addon-ai-staging-nodes"
    cidr      = "10.2.2.0/24"
    dns_label = "nodes"
    private   = true
  }
  "lb" = {
    name      = "addon-ai-staging-lb"
    cidr      = "10.2.3.0/24"
    dns_label = "lb"
    private   = false
  }
  "db" = {
    name      = "addon-ai-staging-db"
    cidr      = "10.2.4.0/24"
    dns_label = "db"
    private   = true
  }
}

# OKE Cluster - Basic Cluster
cluster_name        = "addon-ai-staging-oke"
kubernetes_version  = "v1.31.1"
cluster_type        = "BASIC_CLUSTER"
is_public_endpoint  = false
availability_domain = "WBkQ:SA-BOGOTA-1-AD-1"
node_image_id       = "ocid1.image.oc1.sa-bogota-1.aaaaaaaalcrfyhysejbsevr32jppcn6vyicrl53f6zofplpieffqvstxluuq"

# Node Pools - VM.Standard.E4.Flex (AMD)
node_pools = {
  "default" = {
    name      = "addon-ai-staging-pool"
    shape     = "VM.Standard.E4.Flex"
    ocpus     = 1
    memory_gb = 8
    size      = 2
  }
}

# PostgreSQL Database - Staging
db_system_name    = "addon-ai-staging-postgres"
db_admin_password = "__DB_ADMIN_PASSWORD__"
db_name           = "addonaistagingdb"
db_backup_enabled = true

# OCIR (Container Registry)
ocir_repository_name = "addon-ai-staging-repo"

# Load Balancer
lb_display_name = "addon-ai-staging-lb"
lb_shape        = "flexible"

# DNS
dns_zone_name = "staging.addon-ai.com"

# IAM
iam_policy_name = "addon-ai-staging-policy"

# Vault
vault_name = "addon-ai-staging-vault"

# WAF
waf_policy_name = "addon-ai-staging-waf"

# Monitoring
monitoring_namespace = "addon-ai-staging-monitoring"
monitoring_alarm_enabled = false