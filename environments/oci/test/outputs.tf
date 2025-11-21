output "vcn_id" { value = module.networking.vcn_id }
output "cluster_id" { value = module.k8s_cluster.cluster_id }
output "database_id" { value = module.database.database_id }
