resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.compartment_id
  display_name   = var.display_name
  shape          = var.shape
  subnet_ids     = var.subnet_ids
  is_private     = var.is_private

  dynamic "shape_details" {
    for_each = var.shape == "flexible" ? [1] : []
    content {
      minimum_bandwidth_in_mbps = var.min_bandwidth_mbps
      maximum_bandwidth_in_mbps = var.max_bandwidth_mbps
    }
  }
}

resource "oci_load_balancer_backend_set" "backend_set" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "istio-backend-set"
  policy           = "LEAST_CONNECTIONS"

  health_checker {
    protocol          = "HTTP"
    port              = 15021
    url_path          = "/healthz/ready"
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}

resource "oci_load_balancer_backend" "backend" {
  count            = length(var.backend_ips)
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.backend_set.name
  ip_address       = var.backend_ips[count.index]
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "oci_load_balancer_certificate" "tls_cert" {
  count              = var.tls_certificate_content != "" ? 1 : 0
  load_balancer_id   = oci_load_balancer_load_balancer.lb.id
  certificate_name   = "lb-tls-cert"
  ca_certificate     = var.ca_certificate_content
  private_key        = var.tls_private_key_content
  public_certificate = var.tls_certificate_content
}

resource "oci_load_balancer_listener" "https_listener" {
  count                    = var.enable_https ? 1 : 0
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "https-listener"
  default_backend_set_name = oci_load_balancer_backend_set.backend_set.name
  port                     = 443
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = var.tls_certificate_content != "" ? oci_load_balancer_certificate.tls_cert[0].certificate_name : null
    verify_peer_certificate = false
  }
}

resource "oci_load_balancer_listener" "http_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "http-listener"
  default_backend_set_name = oci_load_balancer_backend_set.backend_set.name
  port                     = 80
  protocol                 = "HTTP"
}
