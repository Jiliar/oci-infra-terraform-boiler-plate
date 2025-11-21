# Try to use existing zone first, create if not found
data "oci_dns_zones" "existing_zones" {
  compartment_id = var.compartment_id
  name           = var.zone_name
}

resource "oci_dns_zone" "zone" {
  count          = length(data.oci_dns_zones.existing_zones.zones) == 0 ? 1 : 0
  compartment_id = var.compartment_id
  name           = var.zone_name
  zone_type      = var.zone_type
}

locals {
  zone_id = length(data.oci_dns_zones.existing_zones.zones) > 0 ? data.oci_dns_zones.existing_zones.zones[0].id : oci_dns_zone.zone[0].id
}

resource "oci_dns_rrset" "lb_a_record" {
  count          = var.lb_ip_address != "" ? 1 : 0
  zone_name_or_id = local.zone_id
  domain          = var.domain_name != "" ? var.domain_name : var.zone_name
  rtype           = "A"
  compartment_id  = var.compartment_id

  items {
    domain = var.domain_name != "" ? var.domain_name : var.zone_name
    rdata  = var.lb_ip_address
    rtype  = "A"
    ttl    = 300
  }
}
