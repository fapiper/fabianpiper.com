module "nlb_listener" {
  source = "../../../modules/nlb-listener"

  name              = var.nlb_listener.name
  load_balancer_id  = module.nlb_reference.outputs.id
  listener_port     = var.nlb_listener.port
  health_check_port = var.nlb_listener.health_check_port
}
