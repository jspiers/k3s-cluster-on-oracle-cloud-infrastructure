variable "tenancy_id" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vcn_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  type = map(string)
  default = {
    "servers" = "10.0.0.0/24",
    # "agents"  = "10.0.1.0/24"
  }
}

variable "custom_tags" {
  type = map(string)
  default = {
  }
}

variable "whitelisted_ip_address" {
  type    = string
  default = "0.0.0.0/0"
}

variable "k3s_version" {
  type = string
  # default = "v1.22.6+k3s1"
}