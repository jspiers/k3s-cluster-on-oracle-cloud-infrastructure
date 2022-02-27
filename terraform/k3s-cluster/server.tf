resource "oci_core_instance_configuration" "server" {
  for_each       = local.configs
  compartment_id = var.compartment_id
  display_name   = "Ubuntu 20.04 k3s ${each.key}"
  freeform_tags  = var.custom_tags

  lifecycle {
    ignore_changes = [
      instance_details[0].launch_details[0].source_details[0].image_id
    ]
  }
  instance_details {
    instance_type = "compute"
    launch_details {
      agent_config {
        is_management_disabled = "false"
        is_monitoring_disabled = "false"
        plugins_config {
          desired_state = "DISABLED"
          name          = "Vulnerability Scanning"
        }
        plugins_config {
          desired_state = "ENABLED"
          name          = "Compute Instance Monitoring"
        }
        plugins_config {
          desired_state = "ENABLED"
          name          = "Bastion"
        }
      }
      availability_config {
        recovery_action = "RESTORE_INSTANCE"
      }
      availability_domain = var.availability_domain
      compartment_id      = var.compartment_id
      create_vnic_details {
        assign_private_dns_record = true
        assign_public_ip          = true
        subnet_id                 = oci_core_subnet.subnets["servers"].id
        hostname_label            = "kube"
      }
      # display_name = "oci_core_instance_configuration.server.instance_details.launch_details.display_name"
      instance_options {
        are_legacy_imds_endpoints_disabled = true
      }
      is_pv_encryption_in_transit_enabled = true
      metadata = {
        "ssh_authorized_keys" = var.ssh_public_key
        "user_data"           = data.template_cloudinit_config.server[each.key].rendered
      }
      shape = "VM.Standard.A1.Flex"
      shape_config {
        memory_in_gbs = "6"
        ocpus         = "1"
      }
      source_details {
        image_id    = data.oci_core_images.ubuntu_20_04_arm64.images[0].id
        source_type = "image"
      }
    }
  }
}

resource "oci_core_instance_pool" "servers" {
  for_each = local.configs
  lifecycle {
    create_before_destroy = true
  }
  display_name              = each.key
  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.server[each.key].id
  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = oci_core_subnet.subnets["servers"].id
    fault_domains       = local.fault_domains
  }
  size = each.value.instances
  freeform_tags = merge(
    var.custom_tags,
    { "k3s-node-type" = each.key }
  )

  dynamic "load_balancers" {
    for_each = local.load_balancer_ports
    content {
      backend_set_name = load_balancers.key
      load_balancer_id = oci_load_balancer.lb.id
      port             = load_balancers.value["port"]
      vnic_selection   = "PrimaryVnic"
    }
  }
}
