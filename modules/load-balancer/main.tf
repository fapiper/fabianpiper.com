# Load Balancer Component - Main Configuration
# OCI Network Load Balancer for K3s cluster

# Network Load Balancer
resource "oci_network_load_balancer_network_load_balancer" "k3s_nlb" {
  count = var.enabled ? 1 : 0

  compartment_id                 = var.compartment_ocid
  display_name                   = var.nlb_display_name
  subnet_id                      = var.public_subnet_id
  is_private                     = var.is_private
  is_preserve_source_destination = var.is_preserve_source_destination
  freeform_tags                  = var.common_tags
}

# Backend Set
resource "oci_network_load_balancer_backend_set" "k3s_backend_set" {
  count = var.enabled ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb[0].id
  name                     = var.backend_set_name
  policy                   = var.backend_policy

  health_checker {
    protocol            = var.health_check_protocol
    port                = var.health_check_port
    interval_in_millis  = var.health_check_interval_ms
    timeout_in_millis   = var.health_check_timeout_ms
    retries             = var.health_check_retries
  }
}

# Backend - Ingress Instance
resource "oci_network_load_balancer_backend" "ingress_backend" {
  count = var.enabled ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb[0].id
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_backend_set[0].name
  port                     = 443
  target_id                = var.ingress_instance_id
  ip_address               = var.ingress_private_ip
}

# HTTPS Listener (443)
resource "oci_network_load_balancer_listener" "https_listener" {
  count = var.enabled ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb[0].id
  name                     = var.https_listener_name
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set[0].name
  port                     = var.https_listener_port
  protocol                 = var.https_listener_protocol
}

# HTTP Listener (80)
resource "oci_network_load_balancer_listener" "http_listener" {
  count = var.enabled ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_nlb[0].id
  name                     = var.http_listener_name
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_backend_set[0].name
  port                     = var.http_listener_port
  protocol                 = var.http_listener_protocol
}
