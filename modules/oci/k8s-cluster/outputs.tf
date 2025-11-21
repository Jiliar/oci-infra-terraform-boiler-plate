output "cluster_id" {
  value = oci_containerengine_cluster.oke.id
}

output "cluster_name" {
  value = oci_containerengine_cluster.oke.name
}

output "cluster_endpoints" {
  value = oci_containerengine_cluster.oke.endpoints
}

output "node_pool_ids" {
  value = { for k, v in oci_containerengine_node_pool.pools : k => v.id }
}

output "cluster_endpoint" {
  value     = oci_containerengine_cluster.oke.endpoints[0].kubernetes
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = oci_containerengine_cluster.oke.endpoints[0].public_endpoint
  sensitive = true
}

output "cluster_version" {
  value = oci_containerengine_cluster.oke.kubernetes_version
}

output "cluster_state" {
  value = oci_containerengine_cluster.oke.state
}
