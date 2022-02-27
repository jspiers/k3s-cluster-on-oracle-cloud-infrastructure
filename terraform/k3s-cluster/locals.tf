locals {
  fault_domains = data.oci_identity_fault_domains.fds.fault_domains[*].name

  configs = {
    cluster_init = {
      cluster_init = true
      instances    = 0
    }
    server = {
      cluster_init = false
      instances    = 0
    }
  }
}
