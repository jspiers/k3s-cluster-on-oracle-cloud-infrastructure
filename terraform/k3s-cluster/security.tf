resource "oci_core_default_security_list" "default" {
  compartment_id             = var.compartment_id
  manage_default_resource_id = oci_core_vcn.default.default_security_list_id
  display_name               = "Default"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  ingress_security_rules {
    protocol    = 1 # icmp
    source      = var.whitelisted_ip_address
    description = "Allow icmp from ${var.whitelisted_ip_address}"
  }
  ingress_security_rules {
    protocol    = 6 # tcp
    source      = var.whitelisted_ip_address
    description = "Allow SSH from ${var.whitelisted_ip_address}"
    tcp_options {
      min = 22
      max = 22
    }
  }
  # ingress_security_rules {
  #   protocol    = 6 # tcp
  #   source      = var.whitelisted_ip_address
  #   description = "Allow HTTP from ${var.whitelisted_ip_address}"
  #   tcp_options {
  #     min = 80
  #     max = 80
  #   }
  # }
  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    description = "Allow all from within VCN"
  }
  freeform_tags = var.custom_tags
}

resource "oci_core_security_list" "k8s_api" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "Kubernetes API"
  ingress_security_rules {
    protocol    = 6 # tcp
    source      = "0.0.0.0/0"
    description = "Allow Kubernetes API requests from all"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
  freeform_tags = var.custom_tags
}