output "istio_base_status" {
  description = "Status of Istio Base installation"
  value       = helm_release.istio_base.status
}

output "istiod_status" {
  description = "Status of Istiod installation"
  value       = helm_release.istiod.status
}

output "istio_ingress_status" {
  description = "Status of Istio Ingress Gateway installation"
  value       = helm_release.istio_ingress.status
}

output "gateway_name" {
  description = "Name of the created Istio Gateway"
  value       = var.enable_gateway ? var.gateway_name : null
}

output "virtualservice_name" {
  description = "Name of the created VirtualService"
  value       = var.enable_virtualservice ? var.virtualservice_name : null
}