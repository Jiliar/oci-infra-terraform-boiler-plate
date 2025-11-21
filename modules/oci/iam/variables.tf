variable "compartment_id" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "policy_statements" {
  type    = list(string)
  default = ["Allow group Administrators to manage all-resources in tenancy"]
}

variable "tenancy_ocid" {
  type = string
}
