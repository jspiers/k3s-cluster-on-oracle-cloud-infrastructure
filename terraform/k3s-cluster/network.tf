resource "oci_core_vcn" "default" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "Default VCN"
  dns_label      = "cusk"
  freeform_tags  = var.custom_tags
}

resource "oci_core_subnet" "subnets" {
  for_each       = var.subnet_cidrs
  cidr_block     = each.value
  compartment_id = var.compartment_id
  display_name   = "k3s ${each.key} subnet"
  dns_label      = each.key
  route_table_id = oci_core_vcn.default.default_route_table_id
  vcn_id         = oci_core_vcn.default.id
  security_list_ids = [
    oci_core_default_security_list.default.id,
    oci_core_security_list.k8s_api.id
  ]
  freeform_tags = var.custom_tags
}

resource "oci_core_internet_gateway" "default" {
  compartment_id = var.compartment_id
  display_name   = "Internet Gateway"
  enabled        = "true"
  vcn_id         = oci_core_vcn.default.id
  freeform_tags  = var.custom_tags
}

resource "oci_core_default_route_table" "default" {
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default.id
  }
  manage_default_resource_id = oci_core_vcn.default.default_route_table_id
  freeform_tags              = var.custom_tags
}