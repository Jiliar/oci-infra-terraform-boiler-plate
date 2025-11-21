resource "oci_database_autonomous_database" "postgres" {
  compartment_id           = var.compartment_id
  db_name                  = var.db_name
  display_name             = var.display_name
  admin_password           = var.admin_password
  db_version               = var.db_version
  db_workload              = "OLTP"
  is_free_tier             = var.is_free_tier
  
  # FREE TIER LIMITATIONS - Commented out unsupported features
  # is_auto_scaling_enabled  = var.autoscaling          # Not supported in free tier
  # data_storage_size_in_tbs = var.data_storage_size_in_tbs # Managed automatically in free tier
  # cpu_core_count           = var.cpu_core_count       # Managed automatically in free tier
  # subnet_id                = var.subnet_id            # Not supported in free tier
  # nsg_ids                  = var.nsg_ids              # Not supported in free tier
  # is_mtls_connection_required = var.require_mtls      # Not supported in free tier
}
