variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the key to use for signing"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key to use for signing"
  type        = string
}

variable "region" {
  description = "The region to connect to. Default: eu-frankfurt-1"
  type        = string
  default     = "eu-frankfurt-1"
}

variable "tenancy_id" {
  description = "The tenancy OCID."
  type        = string
}

variable "user_id" {
  description = "The user OCID."
  type        = string
}

variable "ssh_authorized_keys_paths" {
  description = "List of paths to files with authorized SSH keys"
  type        = list(string)
}
