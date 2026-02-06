module "nlb_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "nlb"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}
