# Try to use existing log group first
data "oci_logging_log_groups" "existing_log_groups" {
  compartment_id = var.compartment_id
  display_name   = "${var.namespace}-log-group"
}

resource "oci_logging_log_group" "log_group" {
  count          = length(data.oci_logging_log_groups.existing_log_groups.log_groups) == 0 ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${var.namespace}-log-group"
  description    = "Log group for ${var.namespace}"
}

locals {
  log_group_id = length(data.oci_logging_log_groups.existing_log_groups.log_groups) > 0 ? data.oci_logging_log_groups.existing_log_groups.log_groups[0].id : oci_logging_log_group.log_group[0].id
}

resource "oci_logging_log" "lb_access_log" {
  count        = var.lb_id != "" ? 1 : 0
  display_name = "lb-access-log"
  log_group_id = local.log_group_id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "access"
      resource    = var.lb_id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_id
  }

  is_enabled         = true
  retention_duration = var.log_retention_days
}

resource "oci_logging_log" "waf_log" {
  count        = var.waf_policy_id != "" ? 1 : 0
  display_name = "waf-security-log"
  log_group_id = local.log_group_id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = var.waf_policy_id
      service     = "waf"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_id
  }

  is_enabled         = true
  retention_duration = var.log_retention_days
}

resource "oci_logging_log" "db_log" {
  count        = var.db_id != "" ? 1 : 0
  display_name = "db-slow-query-log"
  log_group_id = local.log_group_id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = var.db_id
      service     = "database"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_id
  }

  is_enabled         = true
  retention_duration = var.log_retention_days
}

resource "oci_monitoring_alarm" "alarm" {
  count                 = var.alarm_enabled && var.alarm_destinations != null && length(var.alarm_destinations) > 0 ? 1 : 0
  compartment_id        = var.compartment_id
  display_name          = "${var.namespace}-alarm"
  is_enabled            = true
  metric_compartment_id = var.compartment_id
  namespace             = var.namespace
  query                 = "CpuUtilization[1m].mean() > 80"
  severity              = "CRITICAL"
  destinations          = var.alarm_destinations
}
