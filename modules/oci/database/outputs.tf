output "database_id" {
  description = "Database ID"
  value       = oci_database_autonomous_database.postgres.id
}

output "database_connection_strings" {
  description = "Database connection strings"
  value       = oci_database_autonomous_database.postgres.connection_strings
  sensitive   = true
}

output "database_connection_urls" {
  description = "Database connection URLs"
  value       = oci_database_autonomous_database.postgres.connection_urls
  sensitive   = true
}

output "database_state" {
  description = "Database state"
  value       = oci_database_autonomous_database.postgres.state
}
