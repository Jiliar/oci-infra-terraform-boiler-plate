output "zone_id" {
  value = local.zone_id
}

output "zone_name" {
  value = length(data.oci_dns_zones.existing_zones.zones) > 0 ? data.oci_dns_zones.existing_zones.zones[0].name : oci_dns_zone.zone[0].name
}

output "nameservers" {
  value = length(data.oci_dns_zones.existing_zones.zones) > 0 ? data.oci_dns_zones.existing_zones.zones[0].nameservers : oci_dns_zone.zone[0].nameservers
}

output "zone_type" {
  value = length(data.oci_dns_zones.existing_zones.zones) > 0 ? data.oci_dns_zones.existing_zones.zones[0].zone_type : oci_dns_zone.zone[0].zone_type
}
