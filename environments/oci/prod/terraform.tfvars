# OCI Authentication - Values replaced by CI/CD from GitHub Secrets
tenancy_ocid   = "__TENANCY_OCID__"
user_ocid      = "__USER_OCID__"
fingerprint    = "__FINGERPRINT__"
private_key    = "__PRIVATE_KEY__"
region         = "sa-bogota-1"
compartment_id = "__COMPARTMENT_ID__"

# Networking
vcn_name        = "addon-ai-prod-vcn"
vcn_cidr_blocks = ["10.3.0.0/16"]
dns_label       = "addonaiprod"

subnets = {
  "control-plane" = {
    name      = "addon-ai-prod-control-plane"
    cidr      = "10.3.1.0/24"
    dns_label = "controlplane"
    private   = true
  }
  "nodes" = {
    name      = "addon-ai-prod-nodes"
    cidr      = "10.3.2.0/24"
    dns_label = "nodes"
    private   = true
  }
  "lb" = {
    name      = "addon-ai-prod-lb"
    cidr      = "10.3.3.0/24"
    dns_label = "lb"
    private   = false
  }
  "db" = {
    name      = "addon-ai-prod-db"
    cidr      = "10.3.4.0/24"
    dns_label = "db"
    private   = true
  }
}

# OKE Cluster - Enhanced Cluster (SLA)
cluster_name        = "addon-ai-prod-oke"
kubernetes_version  = "v1.34.1"
cluster_type        = "ENHANCED_CLUSTER"
is_public_endpoint  = false
availability_domain = "WBkQ:SA-BOGOTA-1-AD-1"
node_image_id       = "ocid1.image.oc1.sa-bogota-1.aaaaaaaalcrfyhysejbsevr32jppcn6vyicrl53f6zofplpieffqvstxluuq"

# Node Pools - E4 Flex (AMD - Always Available)
node_pools = {
  "default" = {
    name      = "addon-ai-prod-pool"
    shape     = "VM.Standard.E4.Flex"
    ocpus     = 2
    memory_gb = 16
    size      = 3
  }
}

# MySQL Database - Production HA
db_system_name    = "addon-ai-prod-mysql"
db_admin_password = "__DB_ADMIN_PASSWORD__"
db_name           = "addonaiproddbash2"
db_backup_enabled = true

# OCIR (Container Registry)
ocir_repository_name = "addon-ai-prod-repo"

# Load Balancer
lb_display_name = "addon-ai-prod-lb"
lb_shape        = "flexible"

# DNS
dns_zone_name = "addon-ai.com"

# IAM
iam_policy_name = "addon-ai-prod-policy"

# Vault
vault_name = "addon-ai-prod-vault"

# WAF
waf_policy_name = "addon-ai-prod-waf"

# Monitoring
monitoring_namespace = "addon-ai-prod-monitoring-ash"
monitoring_alarm_enabled = true
