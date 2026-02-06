locals {
  enabled = data.context_config.main.enabled

  name              = var.name
  load_balancer_id  = var.load_balancer_id
  listener_port     = var.listener_port
  health_check_port = var.health_check_port
}

data "context_config" "main" {}

data "context_label" "main" {
  values = {
    name = local.name
  }
}

resource "oci_network_load_balancer_backend_set" "default" {
  count = local.enabled ? 1 : 0

  health_checker {
    protocol = "TCP"
    port     = local.health_check_port
  }

  name                     = data.context_label.main.rendered
  network_load_balancer_id = local.load_balancer_id
  policy                   = "FIVE_TUPLE"
}

resource "oci_network_load_balancer_listener" "default" {
  count = local.enabled ? 1 : 0

  default_backend_set_name = oci_network_load_balancer_backend_set.default[0].name
  name                     = data.context_label.main.rendered
  network_load_balancer_id = local.load_balancer_id
  port                     = local.listener_port
  protocol                 = "TCP"
}
