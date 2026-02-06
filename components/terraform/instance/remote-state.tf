module "vault_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "vault"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}


module "vcn_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "vcn"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "alb_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "alb"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "nlb_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "nlb"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "alb_listener_ext_cluster_api_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "alb-listener/ext-cluster-api"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "alb_listener_ext_https_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "alb-listener/ext-https"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "alb_listener_ext_video_stream_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "alb-listener/ext-video-stream"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "nlb_listener_cluster_api_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "nlb-listener/cluster-api"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "nlb_listener_msg_publisher_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "nlb-listener/msg-publisher"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "nlb_listener_msg_subscriber_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "nlb-listener/msg-subscriber"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}

module "dns_nlb_reference" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "dns/nlb"

  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
}
