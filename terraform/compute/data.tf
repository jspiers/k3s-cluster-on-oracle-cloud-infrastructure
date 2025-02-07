data "oci_identity_availability_domain" "ad_1" {
  compartment_id = var.compartment_id
  ad_number      = 1
}

data "oci_identity_fault_domains" "fds" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad_1.name
}

# data "oci_identity_availability_domain" "ad_2" {
#   compartment_id = var.tenancy_ocid
#   ad_number      = 2
# }

# data "oci_identity_availability_domain" "ad_3" {
#   compartment_id = var.tenancy_ocid
#   ad_number      = 3
# }

resource "random_string" "cluster_token" {
  length           = 48
  special          = true
  number           = true
  lower            = true
  upper            = true
  override_special = "^@~*#%/.+:;_"
}
