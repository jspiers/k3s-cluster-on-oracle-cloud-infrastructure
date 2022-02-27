data "oci_core_images" "ubuntu_20_04" {
  for_each                 = local.architecture_shapes
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  state                    = "AVAILABLE"
  shape                    = each.value
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  architecture_shapes = {
    server = local.instance_configs["server"].shape
    worker = local.instance_configs["worker"].shape
  }
  image_id = {
    for key, _ in local.architecture_shapes :
    key => data.oci_core_images.ubuntu_20_04[key].images[0].id
  }
}