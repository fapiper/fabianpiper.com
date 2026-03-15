locals {
  enabled = var.enabled

  compartment_ocid = var.compartment_ocid
  vcn_cidr_blocks  = var.vcn_cidr_blocks
  vcn_dns_label    = var.vcn_dns_label

  subnet_cidr_block = var.subnet_cidr_block
  subnet_dns_label  = var.subnet_dns_label
}

data "context_config" "main" {}

data "context_label" "vcn" {
  values = {
    name = "vcn"
  }
}

data "context_tags" "vcn" {
  values = {
    name = "vcn"
  }
}

data "context_label" "subnet" {
  values = {
    name = var.subnet_name
  }
}

data "context_tags" "subnet" {
  values = {
    name = var.subnet_name
  }
}

resource "oci_core_vcn" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  cidr_blocks    = local.vcn_cidr_blocks
  display_name   = data.context_label.vcn.rendered
  dns_label      = local.vcn_dns_label
  freeform_tags  = data.context_tags.vcn.tags
}

resource "oci_core_internet_gateway" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = data.context_label.vcn.rendered
  enabled        = true
  freeform_tags  = data.context_tags.vcn.tags
}

resource "oci_core_default_route_table" "default" {
  count = local.enabled ? 1 : 0

  manage_default_resource_id = oci_core_vcn.default[0].default_route_table_id
  compartment_id             = local.compartment_ocid
  display_name               = data.context_label.vcn.rendered
  freeform_tags              = data.context_tags.vcn.tags
}

# The VCN default security list is managed here so Terraform owns it completely.
# It is intentionally left with NO rules – none of our subnets use it
# (all subnets declare security_list_ids explicitly). This prevents the default
# list from silently inheriting permissive OCI defaults.
resource "oci_core_default_security_list" "internal" {
  count = local.enabled ? 1 : 0

  manage_default_resource_id = oci_core_vcn.default[0].default_security_list_id
  compartment_id             = local.compartment_ocid
  freeform_tags              = data.context_tags.vcn.tags

  # Intentionally empty – no ingress, no egress.
  # Subnets in this VCN use oci_core_security_list.k3s exclusively.
}


# Consolidated K3s security list
resource "oci_core_security_list" "k3s" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = "${data.context_label.subnet.rendered}-k3s"
  freeform_tags  = data.context_tags.subnet.tags

  # Allow all egress (stateful – return traffic for ingress rules is automatic)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all egress"
    stateless   = false
  }

  # SSH ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow SSH ingress"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTP ingress"
    stateless   = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow HTTPS ingress"
    stateless   = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # K3s API ingress
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6"  # TCP
    description = "Allow K3s API ingress"
    stateless   = false

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Allow all internal VCN traffic
  ingress_security_rules {
    source      = local.vcn_cidr_blocks[0]
    protocol    = "all"
    description = "Allow all internal VCN traffic"
    stateless   = false
  }
}

resource "oci_core_subnet" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  cidr_block     = local.subnet_cidr_block
  display_name   = data.context_label.subnet.rendered
  dns_label      = local.subnet_dns_label
  freeform_tags  = data.context_tags.subnet.tags

  # Route table is specified inline to avoid the race condition that would occur
  # with a separate oci_core_route_table_attachment resource: without this, the
  # subnet would temporarily use the empty default route table during apply,
  # which has no internet gateway route and would break cloud-init.
  route_table_id = oci_core_route_table.default[0].id

  # This list is exhaustive – the VCN default security list is NOT included,
  # ensuring only explicitly defined rules govern this subnet's traffic.
  security_list_ids = [
    oci_core_security_list.k3s[0].id
  ]
}

resource "oci_core_route_table" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.default[0].id
  display_name   = data.context_label.subnet.rendered
  freeform_tags  = data.context_tags.subnet.tags

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.default[0].id
  }
}

# REMOVED: oci_core_route_table_attachment
# The route_table_id is now set directly on oci_core_subnet.default above.
# If this resource still exists in your Terraform state, run:
#   terraform state rm 'module.networking.oci_core_route_table_attachment.default[0]'
# before applying, to avoid a conflict.
