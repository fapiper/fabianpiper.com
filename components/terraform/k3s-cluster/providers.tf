provider "oci" {
  # OCI Provider will automatically read from environment variables:
  # - TF_VAR_tenancy_ocid or OCI_TENANCY_OCID
  # - TF_VAR_user_ocid or OCI_USER_OCID
  # - TF_VAR_fingerprint or OCI_FINGERPRINT
  # - TF_VAR_private_key_path or OCI_PRIVATE_KEY_PATH
  # - TF_VAR_region or OCI_REGION

  # We DO set region explicitly to ensure correct endpoint
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
