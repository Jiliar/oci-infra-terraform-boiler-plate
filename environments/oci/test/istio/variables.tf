variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key" { type = string }
variable "region" { type = string }

variable "istio_version" {
  description = "Istio version to install"
  type        = string
  default     = "1.20.0"
}

variable "enable_gateway" {
  description = "Enable Istio Gateway creation"
  type        = bool
  default     = true
}

variable "gateway_name" {
  description = "Name of the Istio Gateway"
  type        = string
  default     = "addon-ai-test-gateway"
}

variable "gateway_namespace" {
  description = "Namespace for the Istio Gateway"
  type        = string
  default     = "default"
}

variable "gateway_hosts" {
  description = "Hosts for the Istio Gateway"
  type        = list(string)
  default     = ["test.addon-ai.com"]
}

variable "enable_virtualservice" {
  description = "Enable VirtualService creation"
  type        = bool
  default     = true
}

variable "virtualservice_name" {
  description = "Name of the VirtualService"
  type        = string
  default     = "addon-ai-test-vs"
}

variable "virtualservice_namespace" {
  description = "Namespace for the VirtualService"
  type        = string
  default     = "default"
}

variable "virtualservice_hosts" {
  description = "Hosts for the VirtualService"
  type        = list(string)
  default     = ["test.addon-ai.com"]
}

variable "virtualservice_destination_host" {
  description = "Destination host for VirtualService"
  type        = string
  default     = "addon-ai-test-service"
}

variable "virtualservice_destination_port" {
  description = "Destination port for VirtualService"
  type        = number
  default     = 80
}

variable "enable_peer_authentication" {
  description = "Enable PeerAuthentication"
  type        = bool
  default     = true
}

variable "mtls_mode" {
  description = "mTLS mode for PeerAuthentication"
  type        = string
  default     = "STRICT"
}