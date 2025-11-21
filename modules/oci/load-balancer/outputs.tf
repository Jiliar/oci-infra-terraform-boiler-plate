output "lb_id" {
  value = oci_load_balancer_load_balancer.lb.id
}

output "load_balancer_id" {
  value = oci_load_balancer_load_balancer.lb.id
}

output "ip_addresses" {
  value = oci_load_balancer_load_balancer.lb.ip_address_details
}

output "public_ip" {
  value = length(oci_load_balancer_load_balancer.lb.ip_address_details) > 0 ? oci_load_balancer_load_balancer.lb.ip_address_details[0].ip_address : null
}

output "private_ip" {
  value = length(oci_load_balancer_load_balancer.lb.ip_address_details) > 1 ? oci_load_balancer_load_balancer.lb.ip_address_details[1].ip_address : null
}

output "lb_state" {
  value = oci_load_balancer_load_balancer.lb.state
}

output "lb_shape" {
  value = oci_load_balancer_load_balancer.lb.shape
}
