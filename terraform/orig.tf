module "network" {
  source = "./network"

  compartment_id = var.compartment_id
  tenancy_id     = var.tenancy_id
}

module "compute" {
  source     = "./compute"
  depends_on = [module.network]

  compartment_id      = var.compartment_id
  tenancy_id          = var.tenancy_id
  subnet_id           = module.network.subnet.id
  permit_ssh_nsg_id   = module.network.permit_ssh.id
  ssh_authorized_keys = [for path in var.ssh_authorized_keys_paths : file(path)]
}

output "cluster_token" {
  value = module.compute.cluster_token
}
