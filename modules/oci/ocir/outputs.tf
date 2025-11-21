output "repository_id" {
  value = local.repository_id
}

output "repository_url" {
  value = length(data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items) > 0 ? "${data.oci_identity_tenancy.current.name}.ocir.io/${data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items[0].display_name}" : "${data.oci_identity_tenancy.current.name}.ocir.io/${oci_artifacts_container_repository.repository[0].display_name}"
}

output "repository_name" {
  value = length(data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items) > 0 ? data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items[0].display_name : oci_artifacts_container_repository.repository[0].display_name
}

output "repository_state" {
  value = length(data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items) > 0 ? data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items[0].state : oci_artifacts_container_repository.repository[0].state
}

data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}
