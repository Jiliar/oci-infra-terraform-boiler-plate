resource "oci_waf_web_app_firewall_policy" "waf_policy" {
  count          = var.waf_enabled ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = var.waf_policy_name

  actions {
    name = var.waf_mode == "prevention" ? "BLOCK" : "ALLOW"
    type = var.waf_mode == "prevention" ? "RETURN_HTTP_RESPONSE" : "ALLOW"
    
    dynamic "body" {
      for_each = var.waf_mode == "prevention" ? [1] : []
      content {
        text = "Access Denied"
        type = "STATIC_TEXT"
      }
    }
    
    code = var.waf_mode == "prevention" ? 403 : null
  }

  request_rate_limiting {
    rules {
      name        = "rate-limit-rule"
      type        = "REQUEST_RATE_LIMITING"
      action_name = var.waf_mode == "prevention" ? "BLOCK" : "ALLOW"
      
      configurations {
        period_in_seconds = 60
        requests_limit    = 100
        action_duration_in_seconds = 60
      }
      
      condition         = "i_contains(keys(http.request.headers), 'user-agent')"
      condition_language = "JMESPATH"
    }
  }

  request_protection {
    rules {
      name        = "protection-rule-${var.waf_mode}"
      type        = "PROTECTION"
      action_name = var.waf_mode == "prevention" ? "BLOCK" : "ALLOW"
      
      protection_capabilities {
        key     = "920350"
        version = 1
      }
    }
    
    dynamic "rules" {
      for_each = var.enable_owasp_rules ? [1] : []
      content {
        name        = "sql-injection-protection"
        type        = "PROTECTION"
        action_name = var.waf_mode == "prevention" ? "BLOCK" : "ALLOW"
        
        protection_capabilities {
          key     = "942100"
          version = 1
        }
        
        protection_capabilities {
          key     = "942200"
          version = 1
        }
      }
    }
    
    dynamic "rules" {
      for_each = var.enable_owasp_rules ? [1] : []
      content {
        name        = "xss-protection"
        type        = "PROTECTION"
        action_name = var.waf_mode == "prevention" ? "BLOCK" : "ALLOW"
        
        protection_capabilities {
          key     = "941100"
          version = 1
        }
        
        protection_capabilities {
          key     = "941110"
          version = 1
        }
      }
    }
  }
}

resource "oci_waf_web_app_firewall" "waf" {
  count                             = var.waf_enabled && var.lb_id != "" ? 1 : 0
  compartment_id                    = var.compartment_id
  backend_type                      = "LOAD_BALANCER"
  load_balancer_id                  = var.lb_id
  web_app_firewall_policy_id        = oci_waf_web_app_firewall_policy.waf_policy[0].id
  display_name                      = "${var.waf_policy_name}-firewall"
}
