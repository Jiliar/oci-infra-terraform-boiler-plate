variable "istio_version" {
  description = "Istio version to install"
  type        = string
  default     = "1.20.0"
}

variable "istiod_values" {
  description = "Helm values for Istiod"
  type        = string
  default     = ""
}

variable "ingress_values" {
  description = "Helm values for Istio Ingress Gateway"
  type        = string
  default     = ""
}

variable "enable_gateway" {
  description = "Enable Istio Gateway creation"
  type        = bool
  default     = true
}

variable "gateway_name" {
  description = "Name of the Istio Gateway"
  type        = string
  default     = "addon-ai-gateway"
}

variable "gateway_namespace" {
  description = "Namespace for the Istio Gateway"
  type        = string
  default     = "default"
}

variable "gateway_hosts" {
  description = "Hosts for the Istio Gateway"
  type        = list(string)
  default     = ["*"]
}

variable "enable_virtualservice" {
  description = "Enable VirtualService creation"
  type        = bool
  default     = true
}

variable "virtualservice_name" {
  description = "Name of the VirtualService"
  type        = string
  default     = "addon-ai-vs"
}

variable "virtualservice_namespace" {
  description = "Namespace for the VirtualService"
  type        = string
  default     = "default"
}

variable "virtualservice_hosts" {
  description = "Hosts for the VirtualService"
  type        = list(string)
  default     = ["*"]
}

variable "virtualservice_destination_host" {
  description = "Destination host for VirtualService"
  type        = string
  default     = "addon-ai-service"
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
  validation {
    condition     = contains(["STRICT", "PERMISSIVE", "DISABLE"], var.mtls_mode)
    error_message = "mtls_mode must be one of: STRICT, PERMISSIVE, DISABLE."
  }
}

variable "enable_tls" {
  description = "Enable TLS/HTTPS on Gateway"
  type        = bool
  default     = false
}

variable "enable_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "Name of the TLS secret (created by Cert-Manager)"
  type        = string
  default     = "dev-addon-ai-tls"
}