# Try to use existing repository first
data "oci_artifacts_container_repositories" "existing_repositories" {
  compartment_id = var.compartment_id
  display_name   = var.repository_name
}

resource "oci_artifacts_container_repository" "repository" {
  count          = length(data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items) == 0 ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.repository_name
  is_public      = var.is_public
}

locals {
  repository_id = length(data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items) > 0 ? data.oci_artifacts_container_repositories.existing_repositories.container_repository_collection[0].items[0].id : oci_artifacts_container_repository.repository[0].id
}
