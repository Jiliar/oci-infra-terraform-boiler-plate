# OCI Authentication - Values replaced by CI/CD from GitHub Secrets
tenancy_ocid   = "__TENANCY_OCID__"
user_ocid      = "__USER_OCID__"
fingerprint    = "__FINGERPRINT__"
private_key    = "__PRIVATE_KEY__"
region         = "sa-bogota-1"
compartment_id = "__COMPARTMENT_ID__"

# Networking
vcn_name        = "addon-ai-test-vcn"
vcn_cidr_blocks = ["10.1.0.0/16"]
dns_label       = "addonaitest"

subnets = {
  "control-plane" = {
    name      = "addon-ai-test-control-plane"
    cidr      = "10.1.1.0/24"
    dns_label = "controlplane"
    private   = true
  }
  "nodes" = {
    name      = "addon-ai-test-nodes"
    cidr      = "10.1.2.0/24"
    dns_label = "nodes"
    private   = true
  }
  "lb" = {
    name      = "addon-ai-test-lb"
    cidr      = "10.1.3.0/24"
    dns_label = "lb"
    private   = false
  }
  "db" = {
    name      = "addon-ai-test-db"
    cidr      = "10.1.4.0/24"
    dns_label = "db"
    private   = true
  }
}

# OKE Cluster
cluster_name        = "addon-ai-test-oke"
kubernetes_version  = "v1.34.1"
cluster_type        = "BASIC_CLUSTER"
is_public_endpoint  = false
availability_domain = "WBkQ:SA-BOGOTA-1-AD-1"
node_image_id       = "ocid1.image.oc1.sa-bogota-1.aaaaaaaalcrfyhysejbsevr32jppcn6vyicrl53f6zofplpieffqvstxluuq"

# Node Pools
node_pools = {
  "default" = {
    name      = "addon-ai-test-pool"
    shape     = "VM.Standard3.Flex"
    ocpus     = 1
    memory_gb = 16
    size      = 1
  }
}

# Database
db_system_name    = "addon-ai-test-postgres"
db_admin_password = "__DB_ADMIN_PASSWORD__"
db_name           = "addonaitestdb"
db_backup_enabled = true

# OCIR (Container Registry)
ocir_repository_name = "addon-ai-test-repo"

# Load Balancer
lb_display_name = "addon-ai-test-lb"
lb_shape        = "flexible"

# DNS
dns_zone_name = "test.addon-ai.com"

# IAM
iam_policy_name = "addon-ai-test-policy"

# Vault
vault_name = "addon-ai-test-vault"

# WAF
waf_policy_name = "addon-ai-test-waf"

# Monitoring
monitoring_namespace = "addon-ai-test-monitoring"
monitoring_alarm_enabled = false