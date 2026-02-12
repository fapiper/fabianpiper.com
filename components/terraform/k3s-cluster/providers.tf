provider "oci" {
  region = var.region
}

provider "context" {
  enabled   = var.enabled
  delimiter = "-"
  property_order = [
    "tenant",
    "environment",
    "stage",
    "name",
  ]
  properties = {
    tenant = {
      required   = true
      max_length = 4
    }
    environment = {
      required = true
    }
    stage = {
      required         = true
      validation_regex = "^(dev|test|prod)"
    }
    name = {
      required = true
    }
  }
  tags_key_case = "title"
  values = {
    tenant      = var.tenant
    environment = var.environment
    stage       = var.stage
    name        = var.name
  }
}
