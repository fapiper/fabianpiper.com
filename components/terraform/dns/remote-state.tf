module "vcn_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "vcn"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "lb_reference" {
  for_each = var.lb

  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = each.value

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

locals {
  ip_addresses = flatten([for lb in module.lb_reference : lb.outputs.ip_addresses])
}
