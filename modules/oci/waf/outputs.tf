output "waf_policy_id" {
  value = var.waf_enabled ? oci_waf_web_app_firewall_policy.waf_policy[0].id : ""
}

output "waf_firewall_id" {
  value = var.waf_enabled && var.lb_id != "" ? oci_waf_web_app_firewall.waf[0].id : ""
}
