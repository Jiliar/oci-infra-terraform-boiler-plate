# Try to use existing dynamic group first
data "oci_identity_dynamic_groups" "existing_groups" {
  compartment_id = var.tenancy_ocid
  name           = "${var.policy_name}-dynamic-group"
}

resource "oci_identity_dynamic_group" "instance_principal" {
  count          = length(data.oci_identity_dynamic_groups.existing_groups.dynamic_groups) == 0 ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.policy_name}-dynamic-group"
  description    = "Dynamic group for instance principals"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}'}"
}

locals {
  dynamic_group_name = length(data.oci_identity_dynamic_groups.existing_groups.dynamic_groups) > 0 ? data.oci_identity_dynamic_groups.existing_groups.dynamic_groups[0].name : oci_identity_dynamic_group.instance_principal[0].name
}

resource "oci_identity_policy" "policy" {
  compartment_id = var.tenancy_ocid
  name           = var.policy_name
  description    = "IAM policy for workload identity"
  statements = concat(
    var.policy_statements,
    [
      "Allow dynamic-group ${local.dynamic_group_name} to read secret-bundles in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${local.dynamic_group_name} to use keys in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${local.dynamic_group_name} to read autonomous-databases in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${local.dynamic_group_name} to manage objects in compartment id ${var.compartment_id}"
    ]
  )
}
