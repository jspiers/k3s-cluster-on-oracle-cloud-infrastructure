resource "oci_load_balancer" "lb" {
  compartment_id = var.compartment_id
  display_name   = "Peter"
  subnet_ids = [
    oci_core_subnet.subnets["servers"].id
  ]
  shape = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  is_private    = false
  freeform_tags = var.custom_tags
}

locals {
  load_balancer_ports = {
    k8s_api = {
      port     = 6443
      check    = "TCP"
      url_path = null
    }
    http = {
      port     = 80
      check    = "HTTP"
      url_path = "/"
    }
    https = {
      port     = 443
      check    = "HTTP"
      url_path = "/"
    }
  }
}

resource "oci_load_balancer_listener" "listener" {
  for_each                 = local.load_balancer_ports
  default_backend_set_name = each.key
  name                     = each.key
  load_balancer_id         = oci_load_balancer.lb.id
  port                     = each.value.port
  protocol                 = each.value.check
}

resource "oci_load_balancer_backend_set" "backend_set" {
  for_each = local.load_balancer_ports
  health_checker {
    protocol = each.value.check
    url_path = each.value.url_path
  }
  name             = each.key
  load_balancer_id = oci_load_balancer.lb.id
  policy           = "LEAST_CONNECTIONS"
}
