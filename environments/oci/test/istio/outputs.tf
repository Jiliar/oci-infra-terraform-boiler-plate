output "istio_base_status" {
  description = "Status of Istio Base installation"
  value       = module.istio.istio_base_status
}

output "istiod_status" {
  description = "Status of Istiod installation"
  value       = module.istio.istiod_status
}

output "istio_ingress_status" {
  description = "Status of Istio Ingress Gateway installation"
  value       = module.istio.istio_ingress_status
}

output "gateway_name" {
  description = "Name of the created Istio Gateway"
  value       = module.istio.gateway_name
}

output "virtualservice_name" {
  description = "Name of the created VirtualService"
  value       = module.istio.virtualservice_name
}

output "cluster_id" {
  description = "OKE Cluster ID from test environment"
  value       = data.terraform_remote_state.test.outputs.cluster_id
}