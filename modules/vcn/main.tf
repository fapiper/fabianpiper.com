locals {
  enabled = data.context_config.main.enabled

  compartment_ocid               = var.compartment_ocid
  name                           = var.name
  ipv4_cidr_blocks               = var.ipv4_cidr_blocks
  dns_label                      = var.dns_label
  default_security_list_deny_all = local.enabled && var.default_security_list_deny_all
  default_route_table_no_routes  = local.enabled && var.default_route_table_no_routes
  internet_gateway_enabled       = local.enabled && var.internet_gateway_enabled
}

data "context_config" "main" {}

data "context_label" "main" {
  values = {
    name = local.name
  }
}

data "context_tags" "main" {
  values = {
    name = local.name
  }
}

resource "oci_core_vcn" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  cidr_blocks    = local.ipv4_cidr_blocks
  display_name   = data.context_label.main.rendered
  dns_label      = local.dns_label
  freeform_tags  = data.context_tags.main.tags
}

# default resource implicitly created if not specified in configuration
# source: https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/securitylists.htm#Default
resource "oci_core_default_security_list" "internal" {
  count = local.default_security_list_deny_all ? 1 : 0

  compartment_id             = local.compartment_ocid
  manage_default_resource_id = oci_core_vcn.default[0].default_security_list_id

  # TODO: move security list rules to appropriate module once created
  #   egress_security_rules {
  #     destination = "0.0.0.0/0"
  #     protocol    = "all"
  #   }
  #
  #   dynamic "ingress_security_rules" {
  #     for_each = local.ipv4_cidr_blocks
  #     content {
  #       protocol = "all"
  #       source   = ingress_security_rules.value
  #     }
  #   }
  freeform_tags = data.context_tags.main.tags
}

# default resource implicitly created if not specified in configuration
# source: https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/managingroutetables.htm#Overview_of_Routing_for_Your_VCN__Working
resource "oci_core_default_route_table" "default" {
  count = local.default_route_table_no_routes ? 1 : 0

  compartment_id             = local.compartment_ocid
  manage_default_resource_id = oci_core_vcn.default[0].default_route_table_id
  display_name               = data.context_label.main.rendered
  freeform_tags              = data.context_tags.main.tags
}

resource "oci_core_internet_gateway" "default" {
  count = local.internet_gateway_enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  vcn_id         = oci_core_vcn.default[0].id
  freeform_tags  = data.context_tags.main.tags
}

resource "oci_dns_resolver" "default" {
  count = local.enabled ? 1 : 0

  resolver_id  = data.oci_core_vcn_dns_resolver_association.default[0].dns_resolver_id
  display_name = data.context_label.main.rendered
  dynamic "attached_views" {
    for_each = data.oci_dns_resolver.default[0].attached_views[*].view_id
    content {
      view_id = attached_views.value
    }
  }
  freeform_tags = data.context_tags.main.tags
}


data "oci_core_vcn_dns_resolver_association" "default" {
  count = local.enabled ? 1 : 0

  vcn_id = oci_core_vcn.default[0].id
}

data "oci_dns_resolver" "default" {
  count = local.enabled ? 1 : 0

  resolver_id = data.oci_core_vcn_dns_resolver_association.default[0].dns_resolver_id
  scope       = "PRIVATE"
}
