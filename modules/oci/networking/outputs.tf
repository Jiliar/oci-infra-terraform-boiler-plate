output "vcn_id" {
  value = oci_core_vcn.main.id
}

output "subnet_ids" {
  value = { for k, v in oci_core_subnet.subnets : k => v.id }
}

output "nat_gateway_id" {
  value = oci_core_nat_gateway.nat.id
}

output "service_gateway_id" {
  value = oci_core_service_gateway.sg.id
}

output "vcn_cidr" {
  value = oci_core_vcn.main.cidr_blocks
}

output "public_subnet_ids" {
  value = [for k, v in oci_core_subnet.subnets : v.id if !v.prohibit_public_ip_on_vnic]
}

output "private_subnet_ids" {
  value = [for k, v in oci_core_subnet.subnets : v.id if v.prohibit_public_ip_on_vnic]
}

output "nat_gateway_ip" {
  value = oci_core_nat_gateway.nat.nat_ip
}

output "internet_gateway_id" {
  value = oci_core_internet_gateway.igw.id
}
