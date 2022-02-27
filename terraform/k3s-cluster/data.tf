data "oci_identity_fault_domains" "fds" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
}

resource "random_password" "k3s_token" {
  length  = 40
  special = false
  upper   = false
  keepers = {
    compartment = var.compartment_id
    region      = var.region
  }
}

locals {
  k3s_config_yaml = yamlencode({
    write-kubeconfig-mode = "0644"
    # flannel-backend       = "wireguard"
    # node_ip = HOW TO SET NODE IP INDIVIDUALLY FOR EACH NODE
    tls-san                     = oci_load_balancer.lb.ip_addresses
    etcd-s3                     = true
    etcd-s3-access-key          = oci_identity_customer_secret_key.k3s.id
    etcd-s3-bucket              = oci_objectstorage_bucket.k3s.name
    etcd-s3-endpoint            = "${oci_objectstorage_bucket.k3s.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
    etcd-s3-folder              = "etcd"
    etcd-s3-secret-key          = oci_identity_customer_secret_key.k3s.key
    etcd-snapshot-schedule-cron = "37 */6 * * *"
    token-file                  = local.token_file_path
    # secrets-encryption = true
    disable = [
      #"coredns",
      "servicelb",
      "traefik",
      "local-storage",
      "metrics-server"
    ]
  })
  token_file_path = "/etc/rancher/k3s/cluster-token"

  cloud_config_yaml = templatefile(
    "${path.module}/scripts/cloud-config.yaml",
    {
      k3s_token       = random_password.k3s_token.result
      k3s_token_file  = local.token_file_path
      k3s_config_yaml = base64encode(local.k3s_config_yaml)
      k3s_version     = var.k3s_version
    }
  )
}

# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config
data "template_cloudinit_config" "server" {
  for_each      = local.configs
  gzip          = true
  base64_encode = true

  # part {
  #   content_type = "text/x-shellscript"
  #   content      = file("${path.module}/scripts/disable-firewall.sh")
  # }

  # https://cloudinit.readthedocs.io/en/latest/topics/examples.html#yaml-examples
  part {
    filename     = "cloud-config.cfg"
    content_type = "text/cloud-config"
    content      = local.cloud_config_yaml
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/scripts/firewall.sh")
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/scripts/install-server.sh.tftpl",
      {
        k3s_version   = var.k3s_version
        cluster_init  = each.value.cluster_init
        kube_api_host = oci_load_balancer.lb.ip_addresses[0]
        kube_api_port = 6443
      }
    )
  }

  # syntax: https://codeinthehole.com/tips/conditional-nested-blocks-in-terraform/
  # dynamic "part" {
  #   for_each = var.install_longhorn ? [1] : []
  #   content {
  #     content_type = "text/x-shellscript"
  #     content = templatefile(
  #       "${path.module}/scripts/install-longhorn.sh",
  #       { longhorn_release = var.longhorn_release }
  #     )
  #   }
  # }
}

data "oci_core_instance_pool_instances" "servers" {
  for_each         = local.configs
  compartment_id   = var.compartment_id
  instance_pool_id = oci_core_instance_pool.servers[each.key].id
}

locals {
  instance_pool_instances = merge([
    for key, value in local.configs : {
      for i in range(value.instances) :
      "${key}_${i}" => data.oci_core_instance_pool_instances.servers[key].instances[i]
    }
  ]...)
}

data "oci_core_instance" "instance" {
  for_each    = local.instance_pool_instances
  instance_id = each.value.id
}

output "ip_address" {
  value = {
    for k, _ in local.instance_pool_instances :
    k => {
      "private" : data.oci_core_instance.instance[k].private_ip
      "public" : data.oci_core_instance.instance[k].public_ip
    }
  }
}
