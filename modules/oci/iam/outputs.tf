output "policy_id" {
  value = oci_identity_policy.policy.id
}

output "dynamic_group_id" {
  value = length(data.oci_identity_dynamic_groups.existing_groups.dynamic_groups) > 0 ? data.oci_identity_dynamic_groups.existing_groups.dynamic_groups[0].id : oci_identity_dynamic_group.instance_principal[0].id
}

output "dynamic_group_name" {
  value = local.dynamic_group_name
}
