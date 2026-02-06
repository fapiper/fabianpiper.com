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

data "oci_objectstorage_namespace" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = local.compartment_ocid
  name           = data.context_label.main.rendered
  namespace      = data.oci_objectstorage_namespace.default[0].namespace

  freeform_tags = data.context_tags.main.tags
}
