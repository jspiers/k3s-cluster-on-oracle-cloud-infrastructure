output "load_balancer" {
  value = oci_load_balancer.lb
}

output "oci_images" {
  value = {
    for image in data.oci_core_images.ubuntu_20_04_arm64.images :
    image.display_name => image.id
  }
}

output "cloud_config_yaml" {
  value = local.cloud_config_yaml
}

output "k3s_config_yaml" {
  value = local.k3s_config_yaml
}

output "server_cloud_config_parts" {
  value = data.template_cloudinit_config.server["server"].part[*]
}