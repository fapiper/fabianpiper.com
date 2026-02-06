module "storage" {
  source = "../../../modules/storage"

  compartment_ocid = var.compartment_ocid
  name             = var.name
}

module "identity_customer_secret_key" {
  source = "../../../modules/identity-customer-secret-key"

  name    = var.name
  user_id = var.user_ocid
}

module "secret" {
  source = "../../../modules/secret"

  compartment_ocid = var.compartment_ocid
  name             = var.name
  value = jsonencode({
    "AWS_ACCESS_KEY_ID" : module.identity_customer_secret_key.access_key_id,
    "AWS_SECRET_ACCESS_KEY" : module.identity_customer_secret_key.secret_access_key,
    "AWS_ENDPOINTS" : "https://${module.storage.namespace}.compat.objectstorage.${var.region}.oraclecloud.com"
  })

  vault_id          = module.vault_reference.outputs.id
  encryption_key_id = module.vault_reference.outputs.encryption_key_id
}
