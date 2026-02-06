locals {
  enabled = data.context_config.main.enabled

  compartment_ocid  = var.compartment_ocid
  name              = var.name
  value             = var.value
  vault_id          = var.vault_id
  encryption_key_id = var.encryption_key_id
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

resource "oci_vault_secret" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  secret_content {
    content_type = "BASE64"
    content      = base64encode(local.value)
  }
  secret_name = data.context_label.main.rendered
  vault_id    = local.vault_id
  key_id      = local.encryption_key_id

  freeform_tags = data.context_tags.main.tags

  lifecycle {
    ignore_changes = all
  }
}
