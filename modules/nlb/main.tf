locals {
  enabled = data.context_config.main.enabled

  compartment_ocid = var.compartment_ocid
  name             = var.name
  subnet_id        = var.subnet_id
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

resource "oci_network_load_balancer_network_load_balancer" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  subnet_id      = local.subnet_id

  is_private = false

  freeform_tags = data.context_tags.main.tags
}
