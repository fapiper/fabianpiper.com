locals {
  enabled = data.context_config.main.enabled

  compartment_ocid = var.compartment_ocid
  name             = var.name

  secrets = {
    "git-username"           = var.git_username
    "git-pat"                = var.git_pat
    "mixpanel-token"         = var.mixpanel_token
    "site-url"               = var.site_url
    "cloudflare-api-token"   = var.cloudflare_api_token
    "cloudflare-account-id"  = var.cloudflare_account_id
    "grafana-admin-password" = var.grafana_admin_password
  }
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

resource "oci_vault_secret" "secrets" {
  for_each = local.enabled ? local.secrets : {}

  compartment_id = local.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = each.key

  secret_content {
    content_type = "BASE64"
    content      = base64encode(each.value)
  }

  freeform_tags = data.context_tags.main.tags

  depends_on = [oci_kms_key.default]
}

moved {
  from = oci_vault_secret.git_username[0]
  to   = oci_vault_secret.secrets["git-username"]
}

moved {
  from = oci_vault_secret.git_pat[0]
  to   = oci_vault_secret.secrets["git-pat"]
}

moved {
  from = oci_vault_secret.mixpanel_token[0]
  to   = oci_vault_secret.secrets["mixpanel-token"]
}

moved {
  from = oci_vault_secret.site_url[0]
  to   = oci_vault_secret.secrets["site-url"]
}

moved {
  from = oci_vault_secret.cloudflare_api_token[0]
  to   = oci_vault_secret.secrets["cloudflare-api-token"]
}

moved {
  from = oci_vault_secret.cloudflare_account_id[0]
  to   = oci_vault_secret.secrets["cloudflare-account-id"]
}

moved {
  from = oci_vault_secret.grafana_admin_password[0]
  to   = oci_vault_secret.secrets["grafana-admin-password"]
}

