locals {
  enabled = data.context_config.main.enabled

  name = var.name

  user_id = var.user_id
}

data "context_config" "main" {}

data "context_label" "main" {
  values = {
    name = local.name
  }
}

resource "oci_identity_customer_secret_key" "default" {
  count = local.enabled ? 1 : 0

  display_name = data.context_label.main.rendered
  user_id      = local.user_id
}
