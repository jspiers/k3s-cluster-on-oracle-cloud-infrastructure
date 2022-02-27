resource "oci_core_instance" "micro_os" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  fault_domain        = element(data.oci_identity_fault_domains.fds.fault_domains, 0).name
  display_name        = "micro_os"
  shape               = local.instance_configs["server"].shape
  source_details {
    source_id   = local.image_id["server"]
    source_type = "image"
  }
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  create_vnic_details {
    subnet_id = var.subnet_id
    # private_ip = local.server_ip_1
    nsg_ids = [var.permit_ssh_nsg_id]
  }
  metadata = {
    "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    "user_data"           = data.template_cloudinit_config.micro_os.rendered
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "oci_core_instance" "server_1" {
  count               = 0
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  fault_domain        = element(data.oci_identity_fault_domains.fds.fault_domains, 0).name
  display_name        = "k3s-server-1"
  shape               = local.instance_configs["server"].shape
  source_details {
    # source_id   = local.instance_configs["server"].source_id
    source_id   = local.image_id["server"]
    source_type = "image"
  }
  shape_config {
    memory_in_gbs = local.instance_configs["server"].ram
    ocpus         = local.instance_configs["server"].ocpus
  }
  create_vnic_details {
    subnet_id  = var.subnet_id
    private_ip = local.server_ip_1
    nsg_ids    = [var.permit_ssh_nsg_id]
  }
  metadata = {
    "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    "user_data"           = data.template_cloudinit_config.server_1.rendered
  }
}

resource "oci_core_instance" "server_2" {
  count               = 0
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  fault_domain        = element(data.oci_identity_fault_domains.fds.fault_domains, 1).name
  display_name        = "k3s-server-2"
  shape               = local.instance_configs["server"].shape
  source_details {
    source_id   = local.image_id["server"]
    source_type = "image"
  }
  shape_config {
    memory_in_gbs = local.instance_configs["server"].ram
    ocpus         = local.instance_configs["server"].ocpus
  }
  create_vnic_details {
    subnet_id  = var.subnet_id
    private_ip = local.server_ip_2
    nsg_ids    = [var.permit_ssh_nsg_id]
  }
  metadata = {
    "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    "user_data"           = data.template_cloudinit_config.server_2.rendered
  }
  depends_on = [oci_core_instance.server_1]
}

resource "oci_core_instance" "worker" {
  count               = length(data.template_cloudinit_config.worker)
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
  fault_domain        = element(data.oci_identity_fault_domains.fds.fault_domains, 2).name
  display_name        = "k3s-worker-${count.index + 1}"
  shape               = local.instance_configs["worker"].shape
  source_details {
    source_id   = local.image_id["worker"]
    source_type = "image"
  }
  shape_config {
    memory_in_gbs = local.instance_configs["worker"].ram
    ocpus         = local.instance_configs["worker"].ocpus
  }
  create_vnic_details {
    subnet_id = var.subnet_id
    nsg_ids   = [var.permit_ssh_nsg_id]
  }
  metadata = {
    "ssh_authorized_keys" = join("\n", var.ssh_authorized_keys)
    "user_data"           = data.template_cloudinit_config.worker[count.index].rendered
  }
  depends_on = [oci_core_instance.server_2]
}
