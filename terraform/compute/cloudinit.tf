# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config
data "template_cloudinit_config" "server_1" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/templates/server_user_data.sh",
      {
        server_1_ip         = local.server_ip_1
        hostname            = "k3s-server-1"
        ssh_authorized_keys = var.ssh_authorized_keys
        token               = random_string.cluster_token.result
        k3os_image          = local.instance_configs["server"].k3os_image
    })
  }
}

data "template_cloudinit_config" "server_2" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/templates/server_user_data.sh",
      {
        server_1_ip         = local.server_ip_1
        hostname            = "k3s-server-2"
        ssh_authorized_keys = var.ssh_authorized_keys
        token               = random_string.cluster_token.result
        k3os_image          = local.instance_configs["server"].k3os_image
    })
  }
}

data "template_cloudinit_config" "worker" {
  count         = 0
  gzip          = true
  base64_encode = true

  # https://cloudinit.readthedocs.io/en/latest/topics/examples.html#yaml-examples
  #   part {
  #     filename     = "cloud-config.cfg"
  #     content_type = "text/cloud-config"
  #     content      = local.cloud_config_yaml
  #   }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/templates/worker_user_data.sh",
      {
        server_1_ip         = local.server_ip_1
        hostname            = "k3s-worker-${count.index + 1}"
        ssh_authorized_keys = var.ssh_authorized_keys
        token               = random_string.cluster_token.result
        k3os_image          = local.instance_configs["worker"].k3os_image
      }
    )
  }
}
