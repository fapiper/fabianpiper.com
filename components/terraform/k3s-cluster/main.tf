module "k3s_cluster" {
  source = "../../../modules/k3s-cluster"

  compartment_ocid    = var.compartment_ocid

  # Network Configuration
  vcn_id              = data.terraform_remote_state.networking.outputs.vcn_id
  vcn_cidr_block      = var.vcn_cidr_block
  public_subnet_id    = data.terraform_remote_state.networking.outputs.subnet_id
  private_subnet_cidr = var.private_subnet_cidr

  # SSH Configuration
  ssh_public_key_path = var.ssh_public_key_path

  # Instance configuration
  instance_shape      = var.instance_shape
  instance_os         = var.instance_os
  instance_os_version = var.instance_os_version

  # Ingress instance
  ingress_display_name   = var.ingress_display_name
  ingress_hostname_label = var.ingress_hostname_label
  ingress_private_ip     = var.ingress_private_ip
  ingress_shape_config   = var.ingress_shape_config

  # Server instance
  server_display_name   = var.server_display_name
  server_hostname_label = var.server_hostname_label
  server_private_ip     = var.server_private_ip
  server_shape_config   = var.server_shape_config

  # Worker instance
  worker_display_name   = var.worker_display_name
  worker_hostname_label = var.worker_hostname_label
  worker_shape_config   = var.worker_shape_config
  enable_worker         = var.enable_worker

  # K3s configuration
  k3s_version            = var.k3s_version
  k3s_token              = var.k3s_token
  initialization_method  = var.initialization_method
  git_pat      = var.git_pat
  git_username = var.git_username
  git_repo_url = var.git_repo_url
  vault_id     = data.terraform_remote_state.vault.outputs.id

  common_tags = var.common_tags
  enabled     = var.enabled
}
