resource "oci_containerengine_cluster" "oke" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = var.is_public_endpoint
    subnet_id            = var.control_plane_subnet_id
  }

  options {
    service_lb_subnet_ids = var.service_lb_subnet_ids
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
  }

  type = var.cluster_type
}

data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

resource "oci_containerengine_node_pool" "pools" {
  for_each = var.node_pools

  compartment_id     = var.compartment_id
  cluster_id         = oci_containerengine_cluster.oke.id
  kubernetes_version = var.kubernetes_version
  name               = each.value.name
  node_shape         = each.value.shape

  node_shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_gb
  }

  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id          = var.node_subnet_id
    }
    size = each.value.size
  }

  node_source_details {
    source_type = "IMAGE"
    image_id    = length(data.oci_containerengine_node_pool_option.node_pool_options.sources) > 0 ? data.oci_containerengine_node_pool_option.node_pool_options.sources[0].image_id : var.node_image_id
  }

  initial_node_labels {
    key   = "name"
    value = each.value.name
  }
}
