locals {
  enabled = data.context_config.main.enabled

  compartment_ocid   = var.compartment_ocid
  name               = var.name
  subnet_id          = var.subnet_id
  ca_certificate     = var.ca_certificate
  private_key_path   = var.private_key_path
  public_certificate = var.public_certificate
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

resource "oci_load_balancer_load_balancer" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  shape          = "flexible"
  subnet_ids = [
    local.subnet_id,
  ]

  ip_mode    = "IPV4"
  is_private = false

  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  freeform_tags = data.context_tags.main.tags
}

resource "oci_load_balancer_certificate" "default" {
  count = local.enabled ? 1 : 0

  certificate_name = random_id.default[0].hex
  load_balancer_id = oci_load_balancer_load_balancer.default[0].id

  ca_certificate     = local.ca_certificate
  private_key        = file(local.private_key_path)
  public_certificate = local.public_certificate
}

resource "random_id" "default" {
  count = local.enabled ? 1 : 0

  prefix      = "${data.context_label.main.rendered}-"
  byte_length = 4
}
