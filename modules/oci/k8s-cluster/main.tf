resource "oci_containerengine_cluster" "oke" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  type               = var.cluster_type

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
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
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = oci_containerengine_cluster.oke.id
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
      subnet_id           = var.node_subnet_id
    }
    size = each.value.size
    
    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids    = [var.node_subnet_id]
    }
    
    freeform_tags = {
      "OKEnodePoolName" = each.value.name
    }
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = var.node_image_id
    boot_volume_size_in_gbs = 50
  }

  initial_node_labels {
    key   = "name"
    value = var.cluster_name
  }

  freeform_tags = {
    "OKEnodePoolName" = each.value.name
  }
}
