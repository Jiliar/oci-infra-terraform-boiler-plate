output "alarm_id" {
  value = var.alarm_enabled ? oci_monitoring_alarm.alarm[0].id : null
}

output "log_group_id" {
  value = local.log_group_id
}

output "lb_access_log_id" {
  value = oci_logging_log.lb_access_log.id
}

output "waf_log_id" {
  value = var.waf_policy_id != "" ? oci_logging_log.waf_log[0].id : null
}

output "db_log_id" {
  value = var.db_id != "" ? oci_logging_log.db_log[0].id : null
}
