data "oci_objectstorage_namespace" "compartment" {
  compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "k3s" {
  compartment_id = var.compartment_id
  name           = "k3s"
  namespace      = data.oci_objectstorage_namespace.compartment.namespace
  storage_tier   = "Standard"
  freeform_tags  = var.custom_tags
}

data "oci_objectstorage_objects" "etcd_snapshots" {
  #Required
  bucket    = oci_objectstorage_bucket.k3s.name
  namespace = data.oci_objectstorage_namespace.compartment.namespace

  #Optional
  delimiter = "/"
  # end = var.object_end
  # fields = var.object_fields
  prefix = "etcd/"
  # start = var.object_start
  # start_after = var.object_start_after
}

resource "oci_identity_user" "k3s" {
  compartment_id = var.tenancy_id
  description    = "K3S user (for S3)"
  name           = "k3s"
  email          = "k3s@cusk.io"
  freeform_tags  = var.custom_tags
}

resource "oci_identity_group" "k3s_read_write" {
  compartment_id = var.tenancy_id
  description    = "k3s bucket read and write"
  name           = "k3s_read_write"
  freeform_tags  = var.custom_tags
}

resource "oci_identity_user_group_membership" "k3s_read_write" {
  group_id = oci_identity_group.k3s_read_write.id
  user_id  = oci_identity_user.k3s.id
}

# https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/commonpolicies.htm#top
resource "oci_identity_policy" "k3s_read_write" {
  compartment_id = var.compartment_id
  description    = "Allowed to read/write k3s bucket"
  name           = "k3s_read_write"
  statements = [
    "Allow group ${oci_identity_group.k3s_read_write.name} to read buckets in compartment id ${var.compartment_id}",
    "Allow group ${oci_identity_group.k3s_read_write.name} to manage objects in compartment id ${var.compartment_id}" # where target.bucket.name=${oci_objectstorage_bucket.k3s.name}",
  ]
  freeform_tags = var.custom_tags
}

resource "oci_identity_customer_secret_key" "k3s" {
  display_name = "K3S etcd S3 Credentials"
  user_id      = oci_identity_user.k3s.id
}

output "s3_credentials" {
  value = {
    endpoint = "${oci_objectstorage_bucket.k3s.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
    bucket   = oci_objectstorage_bucket.k3s.name
    access   = oci_identity_customer_secret_key.k3s.id
    secret   = oci_identity_customer_secret_key.k3s.key
  }
  # TODO: make sensitive
  # sensitive = true
}