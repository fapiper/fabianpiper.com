module "alb_listener" {
  source = "../../../modules/alb-listener"

  name              = var.alb_listener.name
  load_balancer_id  = module.alb_reference.outputs.id
  listener_port     = var.alb_listener.port
  health_check_port = var.alb_listener.health_check_port
  use_ssl           = var.alb_listener.use_ssl
  certificate_name  = module.alb_reference.outputs.certificate_name
}
