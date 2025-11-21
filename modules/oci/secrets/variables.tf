variable "compartment_id" {
  type = string
}

variable "vault_name" {
  type = string
}

variable "vault_type" {
  type    = string
  default = "DEFAULT"
}

variable "db_username" {
  type    = string
  default = ""
}

variable "db_password" {
  type      = string
  default   = ""
  sensitive = true
}
