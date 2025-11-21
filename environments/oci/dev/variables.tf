variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key" { type = string }
variable "region" { type = string }
variable "compartment_id" { type = string }
variable "vcn_name" { type = string }
variable "vcn_cidr_blocks" { type = list(string) }
variable "dns_label" { type = string }
variable "subnets" { type = map(any) }
variable "cluster_name" { type = string }
variable "kubernetes_version" { type = string }
variable "cluster_type" { type = string }
variable "is_public_endpoint" { type = bool }
variable "availability_domain" { type = string }
variable "node_pools" {
  type = map(any)
  default = {
    "default" = {
      name          = "default"
      shape         = "VM.Standard.E4.Flex" 
      ocpus         = 1
      memory_in_gbs = 8
      node_count    = 2
    }
  }
}

variable "node_image_id" {
  type    = string
  default = "" 
}
variable "db_system_name" { type = string }
variable "db_admin_password" {
  type      = string
  sensitive = true
}
variable "db_name" { type = string }
variable "db_backup_enabled" { type = bool }

variable "ocir_repository_name" { type = string }
variable "lb_display_name" { type = string }
variable "lb_shape" {
  type    = string
  default = "flexible"
}
variable "dns_zone_name" { type = string }
variable "iam_policy_name" { type = string }
variable "monitoring_namespace" { type = string }
variable "monitoring_alarm_enabled" {
  type    = bool
  default = false
}
variable "vault_name" { type = string }
variable "waf_policy_name" { type = string }
