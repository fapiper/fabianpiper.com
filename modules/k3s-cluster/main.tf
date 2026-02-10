locals {
  enabled = var.enabled

  compartment_ocid = var.compartment_ocid

  vcn_id              = var.vcn_id
  vcn_cidr_block      = var.vcn_cidr_block
  public_subnet_id    = var.public_subnet_id
  private_subnet_cidr = var.private_subnet_cidr

  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
  selected_ad    = data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain].name

  k3s_version = var.k3s_version
  k3s_token   = var.k3s_token

  use_cloud_init = var.initialization_method == "cloud-init"
}

data "context_config" "main" {}


data "oci_identity_availability_domains" "ads" {
  compartment_id = local.compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = local.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.instance_os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}


resource "oci_core_instance" "ingress" {
  count = var.enabled ? 1 : 0

  compartment_id      = local.compartment_ocid
  availability_domain = local.selected_ad
  display_name        = var.ingress_display_name
  shape               = var.instance_shape
  freeform_tags       = var.common_tags

  shape_config {
    ocpus         = var.ingress_shape_config.ocpus
    memory_in_gbs = var.ingress_shape_config.memory_in_gbs
  }

  create_vnic_details {
    subnet_id              = var.public_subnet_id
    assign_public_ip       = true
    private_ip             = var.ingress_private_ip
    skip_source_dest_check = true  # Required for NAT functionality
    hostname_label         = var.ingress_hostname_label
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = local.use_cloud_init ? base64encode(templatefile("${path.module}/user-data/ingress.yaml", {
      server_ip = var.server_private_ip
      k3s_token = var.k3s_token
    })) : null
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }
}

data "oci_core_private_ips" "ingress_ips" {
  count = var.enabled ? 1 : 0

  subnet_id  = var.public_subnet_id
  ip_address = var.ingress_private_ip

  depends_on = [oci_core_instance.ingress]
}

resource "oci_core_route_table" "private_rt" {
  count = var.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "k3s-private-rt"
  freeform_tags  = var.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.ingress_ips[0].private_ips[0].id
  }
}

# Security list for private subnet - allows all internal communication
resource "oci_core_security_list" "private_subnet_sl" {
  count = var.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "k3s-private-subnet-sl"
  freeform_tags  = var.common_tags

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all egress"
  }

  # Allow all ingress from VCN CIDR
  ingress_security_rules {
    source      = var.vcn_cidr_block
    protocol    = "all"
    description = "Allow all traffic from VCN"
  }
}

resource "oci_core_subnet" "private_subnet" {
  count = var.enabled ? 1 : 0

  compartment_id             = local.compartment_ocid
  vcn_id                     = var.vcn_id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "k3s-private-subnet"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private_rt[0].id
  security_list_ids          = [oci_core_security_list.private_subnet_sl[0].id]
  prohibit_public_ip_on_vnic = true
  freeform_tags              = var.common_tags
}

resource "oci_core_instance" "server" {
  count = var.enabled ? 1 : 0

  compartment_id      = local.compartment_ocid
  availability_domain = local.selected_ad
  display_name        = var.server_display_name
  shape               = var.instance_shape
  freeform_tags       = var.common_tags

  shape_config {
    ocpus         = var.server_shape_config.ocpus
    memory_in_gbs = var.server_shape_config.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet[0].id
    assign_public_ip = false
    private_ip       = var.server_private_ip
    hostname_label   = var.server_hostname_label
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = local.use_cloud_init ? base64encode(templatefile("${path.module}/user-data/server.yaml", {
      public_ip     = oci_core_instance.ingress[0].public_ip
      k3s_token     = var.k3s_token
      git_pat       = var.git_pat
      git_username  = var.git_username
      git_repo_url  = var.git_repo_url
    })) : null
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  depends_on = [oci_core_subnet.private_subnet]
}

resource "oci_core_instance" "worker" {
  count = var.enabled && var.enable_worker ? 1 : 0

  compartment_id      = local.compartment_ocid
  availability_domain = local.selected_ad
  display_name        = var.worker_display_name
  shape               = var.instance_shape
  freeform_tags       = var.common_tags

  shape_config {
    ocpus         = var.worker_shape_config.ocpus
    memory_in_gbs = var.worker_shape_config.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet[0].id
    assign_public_ip = false
    hostname_label   = var.worker_hostname_label
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = local.use_cloud_init ? base64encode(templatefile("${path.module}/user-data/worker.yaml", {
      server_ip = var.server_private_ip
      k3s_token = var.k3s_token
    })) : null
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  depends_on = [oci_core_instance.server]
}
