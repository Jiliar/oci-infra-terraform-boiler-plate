variable "compartment_id" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "zone_type" {
  type    = string
  default = "PRIMARY"
}

variable "lb_ip_address" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
}
