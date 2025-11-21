terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = { source = "oracle/oci", version = "~> 5.0" }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = "terraform-state"
  access_type    = "NoPublicAccess"

  versioning = "Enabled"
}
