variable "compartment_id" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "is_public" {
  type    = bool
  default = false
}

variable "tenancy_ocid" {
  type = string
}
