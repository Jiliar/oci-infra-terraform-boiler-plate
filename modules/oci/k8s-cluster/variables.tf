variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "cluster_name" {
  description = "OKE cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vcn_id" {
  description = "VCN ID"
  type        = string
}

variable "control_plane_subnet_id" {
  description = "Control plane subnet ID"
  type        = string
}

variable "node_subnet_id" {
  description = "Node subnet ID"
  type        = string
}

variable "service_lb_subnet_ids" {
  description = "Service LB subnet IDs"
  type        = list(string)
}

variable "is_public_endpoint" {
  description = "Enable public endpoint"
  type        = bool
  default     = false
}

variable "pods_cidr" {
  description = "CIDR for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR for services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "cluster_type" {
  description = "Cluster type (BASIC_CLUSTER or ENHANCED_CLUSTER)"
  type        = string
  default     = "BASIC_CLUSTER"
}

variable "availability_domain" {
  description = "Availability domain"
  type        = string
}

variable "node_image_id" {
  description = "Node image OCID"
  type        = string
}

variable "node_pools" {
  description = "Node pools configuration"
  type = map(object({
    name         = string
    shape        = string
    ocpus        = number
    memory_gb    = number
    size         = number
    preemptible  = optional(bool, false)
  }))
}

variable "environment" {
  description = "Environment name (dev, test, staging, prod)"
  type        = string
  default     = "dev"
}
