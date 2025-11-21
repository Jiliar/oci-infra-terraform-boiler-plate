variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "vcn_name" {
  description = "VCN name"
  type        = string
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks for VCN"
  type        = list(string)
}

variable "dns_label" {
  description = "DNS label for VCN"
  type        = string
}

variable "subnets" {
  description = "Subnets configuration"
  type = map(object({
    name      = string
    cidr      = string
    dns_label = string
    private   = bool
  }))
}
