variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "display_name" {
  description = "Display name"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "db_version" {
  description = "Database version"
  type        = string
  default     = "19c"
}

variable "is_free_tier" {
  description = "Use free tier"
  type        = bool
  default     = false
}

# FREE TIER LIMITATIONS - Variables commented out
# variable "subnet_id" {
#   description = "Subnet ID"
#   type        = string
# }
# 
# variable "nsg_ids" {
#   description = "Network Security Group IDs"
#   type        = list(string)
#   default     = []
# }
# 
# variable "cpu_core_count" {
#   description = "CPU core count (OCPU)"
#   type        = number
#   default     = 1
# }
# 
# variable "data_storage_size_in_tbs" {
#   description = "Data storage size in TBs"
#   type        = number
#   default     = 1
# }
# 
# variable "autoscaling" {
#   description = "Enable auto scaling"
#   type        = bool
#   default     = false
# }
# 
# variable "backup_enabled" {
#   description = "Enable backups"
#   type        = bool
#   default     = true
# }
# 
# variable "backup_retention_days" {
#   description = "Backup retention days"
#   type        = number
#   default     = 7
# }
# 
# variable "require_mtls" {
#   description = "Require mTLS connection"
#   type        = bool
#   default     = true
# }
