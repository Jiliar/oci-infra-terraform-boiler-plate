variable "compartment_id" {
  type = string
}

variable "display_name" {
  type = string
}

variable "shape" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "is_private" {
  type    = bool
  default = false
}

variable "min_bandwidth_mbps" {
  type    = number
  default = 10
}

variable "max_bandwidth_mbps" {
  type    = number
  default = 100
}

variable "backend_ips" {
  type    = list(string)
  default = []
}

variable "tls_certificate_content" {
  type    = string
  default = ""
}

variable "tls_private_key_content" {
  type    = string
  default = ""
}

variable "ca_certificate_content" {
  type    = string
  default = ""
}

variable "enable_https" {
  type    = bool
  default = false
}
