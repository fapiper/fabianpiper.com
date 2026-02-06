module "alb_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "alb"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}
