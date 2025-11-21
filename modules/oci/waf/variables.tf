variable "compartment_id" {
  type = string
}

variable "waf_policy_name" {
  type = string
}

variable "waf_enabled" {
  type    = bool
  default = false
}

variable "waf_mode" {
  type    = string
  default = "disabled"
  validation {
    condition     = contains(["disabled", "monitoring", "prevention"], var.waf_mode)
    error_message = "WAF mode must be: disabled, monitoring, or prevention."
  }
}

variable "enable_owasp_rules" {
  type        = bool
  default     = false
  description = "Enable OWASP SQL Injection and XSS protection rules"
}

variable "lb_id" {
  type    = string
  default = ""
}
