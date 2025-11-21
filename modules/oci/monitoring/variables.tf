variable "compartment_id" {
  type = string
}

variable "namespace" {
  type = string
}

variable "alarm_enabled" {
  type    = bool
  default = true
}

variable "lb_id" {
  type    = string
  default = ""
}

variable "waf_policy_id" {
  type    = string
  default = ""
}

variable "db_id" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "alarm_destinations" {
  type    = list(string)
  default = null
}
