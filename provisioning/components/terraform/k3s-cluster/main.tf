module "k3s_cluster" {
  source = "../../../modules/k3s-cluster"

  compartment_ocid       = var.compartment_ocid
  name                   = var.name
  availability_domain    = var.availability_domain
  vcn_id                 = var.vcn_id
  public_subnet_id       = var.public_subnet_id
  ssh_public_key         = var.ssh_public_key
  instance_shape         = var.instance_shape
  instance_os            = var.instance_os
  instance_os_version    = var.instance_os_version
  server_ocpus           = var.server_ocpus
  server_memory_in_gbs   = var.server_memory_in_gbs
  k3s_token              = var.k3s_token
  enabled                = var.enabled
}
