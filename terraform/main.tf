terraform {
  backend "http" {}
  required_version = ">= 0.15"
  required_providers {
    oci = "~> 4.65"
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_id
  user_ocid        = var.user_id
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}
