provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

provider "context" {
  enabled = var.enabled
  values = {
    tenant      = var.tenant
    environment = var.environment
    stage       = var.stage
    name        = var.name
  }
}
