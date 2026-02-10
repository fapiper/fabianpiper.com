locals {
  enabled = data.context_config.main.enabled

  compartment_ocid = var.compartment_ocid
  name             = var.name
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

resource "oci_kms_vault" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  vault_type     = "DEFAULT"
  freeform_tags  = data.context_tags.main.tags
}

resource "time_sleep" "wait_for_vault_dns" {
  count = local.enabled ? 1 : 0

  depends_on = [oci_kms_vault.default[0]]

  create_duration = "90s"
}

resource "oci_kms_key" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  display_name   = data.context_label.main.rendered
  key_shape {
    algorithm = "AES"
    length    = 32
  }
  management_endpoint = oci_kms_vault.default[0].management_endpoint
  protection_mode     = "SOFTWARE"
  freeform_tags       = data.context_tags.main.tags

  depends_on = [time_sleep.wait_for_vault_dns]
}
