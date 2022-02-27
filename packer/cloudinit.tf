# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config

locals {
  combustion_script = {
    path       = "/root/script"
    permission = "0644"
    owner      = "root:root"
    content    = <<-EOF
      #!/bin/bash
      sed -i 's#NETCONFIG_NIS_SETDOMAINNAME="yes"#NETCONFIG_NIS_SETDOMAINNAME="no"#g' /etc/sysconfig/network/config
      sed -i 's#WAIT_FOR_INTERFACES="30"#WAIT_FOR_INTERFACES="60"#g' /etc/sysconfig/network/config
      sed -i 's#CHECK_DUPLICATE_IP="yes"#CHECK_DUPLICATE_IP="no"#g' /etc/sysconfig/network/config
      # combustion: network
      rpm --import https://rpm.rancher.io/public.key
      zypper refresh
      zypper --gpg-auto-import-keys install -y https://rpm.rancher.io/k3s/stable/common/microos/noarch/k3s-selinux-0.4-1.sle.noarch.rpm
      udevadm settle || true
      EOF
  }
  ignition_config = {
    path       = "/root/config.ign"
    permission = "0644"
    owner      = "root:root"
    content = jsonencode({
      ignition = {
        version = "3.0.0"
      }
      passwd = {
        users = [{
          name              = "root"
          sshAuthorizedKeys = var.ssh_authorized_keys
        }]
      }
      storage = {
        files = [
          {
            path      = "/etc/sysconfig/network/ifcfg-eth1"
            mode      = 420
            overwrite = true
            contents  = { "source" = "data:,BOOTPROTO%3D%27dhcp%27%0ASTARTMODE%3D%27auto%27" }
          },
          {
            path      = "/etc/ssh/sshd_config.d/kube-hetzner.conf"
            mode      = 420
            overwrite = true
            contents  = { "source" = "data:,PasswordAuthentication%20no%0AX11Forwarding%20no%0AMaxAuthTries%202%0AAllowTcpForwarding%20no%0AAllowAgentForwarding%20no%0AAuthorizedKeysFile%20.ssh%2Fauthorized_keys" }
          }
        ]
      }
    })
  }
  re_cloud_init = {
    path       = "/usr/local/bin/re-cloud-init"
    permission = "0755"
    owner      = "root:root"
    content    = <<-EOF
          #!/bin/sh
          cloud-init clean --logs
          cloud-init init --local
          cloud-init init
          cloud-init modules --mode=config
          cloud-init modules --mode=final
          EOF
  }
  test_host_port = {
    path       = "/usr/local/bin/test-host-port"
    permission = "0755"
    owner      = "root:root"
    content    = file("${path.module}/templates/test_host_port.sh")
  }

  cloud_config = {
    package_update             = true
    package_upgrade            = true
    package_reboot_if_required = true
    packages = [
      "jq"
    ]
    write_files = [
      local.ignition_config,
      local.combustion_script,
      local.re_cloud_init,
      local.test_host_port
    ]
    snap = {
      commands = {
        "00" = "snap install yq"
      }
    }
    runcmd = [
      "set -x",
      [
        "curl", "-so", "/run/cloud-init/vnics.json",
        "-H", "Authorization: Bearer Oracle",
        "http://169.254.169.254/opc/v2/vnics/"
      ],
      "env",
      "set",
      "'echo whoami = $(whoami)'",
      # "'ln -s "/var/lib/cloud/instance/scripts/part-003" $HOME/part-003'",
    ]
    final_message = "Jeff sends his regards. The system is up after $UPTIME seconds."
  }
}

data "template_cloudinit_config" "micro_os" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.cfg"
    content_type = "text/cloud-config"
    content      = yamlencode(local.cloud_config)
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/templates/install_micro_os.sh",
      {
        combustion_path = "/root/combustion"
        ignition_path   = local.ignition_config.path
      }
    )
  }
}

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
