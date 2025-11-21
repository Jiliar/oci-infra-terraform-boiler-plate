resource "oci_kms_vault" "vault" {
  compartment_id = var.compartment_id
  display_name   = var.vault_name
  vault_type     = var.vault_type
}

resource "oci_kms_key" "kms_key" {
  compartment_id      = var.compartment_id
  display_name        = "${var.vault_name}-key"
  management_endpoint = oci_kms_vault.vault.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "db_username" {
  count          = var.db_username != "" ? 1 : 0
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.kms_key.id
  secret_name    = "db-username"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.db_username)
  }
}

resource "oci_vault_secret" "db_password" {
  count          = var.db_password != "" ? 1 : 0
  compartment_id = var.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.kms_key.id
  secret_name    = "db-password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.db_password)
  }
}
