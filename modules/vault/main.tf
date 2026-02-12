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

resource "oci_vault_secret" "git_username" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = "git-username"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.git_username)
  }

  freeform_tags = data.context_tags.main.tags

  depends_on = [oci_kms_key.default]
}

resource "oci_vault_secret" "git_pat" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = "git-pat"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.git_pat)
  }

  freeform_tags = data.context_tags.main.tags

  depends_on = [oci_kms_key.default]
}

resource "oci_vault_secret" "mixpanel_token" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = "mixpanel-token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.mixpanel_token)
  }

  freeform_tags = data.context_tags.main.tags

  depends_on = [oci_kms_key.default]
}

resource "oci_vault_secret" "site_url" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = "site-url"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.site_url)
  }

  freeform_tags = data.context_tags.main.tags

  depends_on = [oci_kms_key.default]
}

