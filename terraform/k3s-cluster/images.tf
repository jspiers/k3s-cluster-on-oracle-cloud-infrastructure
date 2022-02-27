data "oci_core_images" "ubuntu_20_04_arm64" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  state                    = "AVAILABLE"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_id_ubuntu_latest = data.oci_core_images.ubuntu_20_04_arm64.images[0].id
}