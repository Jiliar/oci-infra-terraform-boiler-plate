output "vault_id" {
  value = oci_kms_vault.vault.id
}

output "vault_endpoint" {
  value = oci_kms_vault.vault.management_endpoint
}

output "vault_crypto_endpoint" {
  value = oci_kms_vault.vault.crypto_endpoint
}

output "vault_state" {
  value = oci_kms_vault.vault.state
}

output "kms_key_id" {
  value = oci_kms_key.kms_key.id
}

output "db_username_secret_id" {
  value = length(oci_vault_secret.db_username) > 0 ? oci_vault_secret.db_username[0].id : null
}

output "db_password_secret_id" {
  value = length(oci_vault_secret.db_password) > 0 ? oci_vault_secret.db_password[0].id : null
}
