# Free K3s Cluster on Oracle Cloud

This is a DEPRECATED project.
The goal was to automate setting up of a K3S cluster on Oracle Cloud (OCI) by installing Suse MicroOS (descendant of Rancher K3OS after it was acquired by Suse).
But the OCI machines do not seem to accept the Suse MicroOS images that I have tried.

## Technologies Employed

- Oracle Cloud free tier machines (ARM Ampere)
- Terraform
- Packer
- Suse MicroOS (aarch64)

## Suse MicroOS on aarch64

- [kube-hetzner](https://github.com/jspiers/kube-hetzner/blob/master/modules/host/locals.tf)
  - [from k3os to micro-os](https://github.com/kube-hetzner/kube-hetzner/issues/35)
- [packer + qemu](https://blogs.oracle.com/cloud-infrastructure/post/using-packer-and-virtualbox-to-bring-your-own-image-into-oracle-cloud-infrastructure)?
  - There is a `openSUSE-MicroOS.aarch64-k3s-kvm-and-xen.qcow2` [here](https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/) (found via [this](https://en.opensuse.org/Portal:MicroOS/Downloads))
