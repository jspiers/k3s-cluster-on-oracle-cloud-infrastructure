variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
}

variable "tenancy_id" {
  description = "The tenancy OCID."
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the bastion instance"
  type        = string
}

variable "permit_ssh_nsg_id" {
  description = "NSG to permit SSH"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "List of authorized SSH keys"
  type        = list(string)
}

variable "master_1_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}

variable "master_2_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}

variable "worker_user_data" {
  description = "Commands to be ran at boot for the bastion instance. Default installs Kali headless"
  type        = string
  default     = <<EOT
#!/bin/sh
sudo apt-get update
EOT
}

locals {
  server_ip_1  = "10.0.0.11"
  server_ip_2  = "10.0.0.12"
  worker_ip_0  = "10.0.0.21"
  worker_ip_1  = "10.0.0.22"
  k3os_version = "v0.21.5-k3s2r1"
  instance_configs = {
    server = {
      shape      = "VM.Standard.A1.Flex"
      ocpus      = 2
      ram        = 12
      k3os_image = "https://github.com/rancher/k3os/releases/download/${local.k3os_version}/k3os-arm64.iso"
    }
    worker = {
      shape      = "VM.Standard.E2.1.Micro"
      ocpus      = 1
      ram        = 1
      k3os_image = "https://github.com/rancher/k3os/releases/download/${local.k3os_version}/k3os-amd64.iso"
    }
  }
}
